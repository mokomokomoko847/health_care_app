import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/main.dart';
import 'package:health_care_app/models/glucose_record.dart';
import 'package:health_care_app/pages/calendar_page.dart';
import 'package:health_care_app/pages/daily_detail_page.dart';
import 'package:health_care_app/pages/record_input_page.dart';
import 'package:health_care_app/repositories/glucose_record_repository.dart';

import 'support/fake_auth_service.dart';

class ControlledRepository implements GlucoseRecordRepository {
  final GlucoseRecordRepository delegate = FirestoreGlucoseRecordRepository(
    firestore: FakeFirebaseFirestore(),
  );
  Object? failure;
  Completer<void>? pending;
  int createCalls = 0;

  @override
  String newRecordId() => delegate.newRecordId();

  @override
  Future<void> create(
    String userId,
    String recordId,
    GlucoseRecord record,
  ) async {
    createCalls++;
    if (pending != null) await pending!.future;
    if (failure != null) throw failure!;
    await delegate.create(userId, recordId, record);
  }

  @override
  Future<List<GlucoseRecord>> loadRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    if (failure != null) throw failure!;
    return delegate.loadRange(userId, start, end);
  }
}

void main() {
  Future<void> open(
    WidgetTester tester,
    GlucoseRecordRepository repository, {
    FakeAuthService? auth,
  }) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        auth: auth ?? FakeAuthService(isSignedIn: true, isEmailVerified: true),
        repository: repository,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> fill(WidgetTester tester) async {
    await tester.ensureVisible(find.text('記録入力'));
    await tester.tap(find.text('記録入力'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123');
    await tester.scrollUntilVisible(
      find.text('記録を保存'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('保存成功でカレンダーへ戻り、記録日と日別詳細に保存値を反映する', (tester) async {
    final repository = ControlledRepository();
    await open(tester, repository);
    await fill(tester);
    await tester.tap(find.text('記録を保存'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordInputPage), findsNothing);
    final calendar = tester.widget<CalendarPage>(find.byType(CalendarPage));
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    expect(calendar.recordedDates, contains(day));
    await tester.tap(
      find.byKey(ValueKey('day-${day.year}-${day.month}-${day.day}')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DailyDetailPage), findsOneWidget);
    expect(find.text('123'), findsOneWidget);
    expect(find.text('1件の記録'), findsOneWidget);
  });

  testWidgets('保存中は重複実行と戻る操作を防ぎ、失敗後も入力を保持して再試行できる', (tester) async {
    final repository = ControlledRepository();
    await open(tester, repository);
    await fill(tester);
    repository.pending = Completer<void>();
    repository.failure = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    await tester.tap(find.text('記録を保存'));
    await tester.pump();
    expect(find.text('保存中…'), findsOneWidget);
    await tester.tap(find.text('保存中…'), warnIfMissed: false);
    await tester.binding.handlePopRoute();
    await tester.pump();
    expect(repository.createCalls, 1);
    expect(find.byType(RecordInputPage), findsOneWidget);
    repository.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('通信できません。接続を確認して、もう一度お試しください。'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    final fields = tester.widgetList<TextField>(find.byType(TextField));
    expect(fields.first.controller!.text, '123');
    repository.failure = null;
    repository.pending = null;
    await tester.scrollUntilVisible(
      find.text('記録を保存'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('記録を保存'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
  });

  testWidgets('取得失敗から再試行でき、別ユーザーへの切替時に前の記録を表示しない', (tester) async {
    final repository = ControlledRepository();
    final auth = FakeAuthService(isSignedIn: true, isEmailVerified: true);
    final now = DateTime.now();
    await repository.create(
      'test-user',
      'first',
      GlucoseRecord(
        recordedAt: now,
        bloodSugarMgDl: 123,
        mealTiming: MealTiming.beforeMeal,
        memo: '',
        photoPaths: [],
      ),
    );
    repository.failure = FirebaseException(
      plugin: 'cloud_firestore',
      code: 'unavailable',
    );
    await open(tester, repository, auth: auth);
    expect(find.text('再試行'), findsOneWidget);
    repository.failure = null;
    await tester.tap(find.text('再試行'));
    await tester.pumpAndSettle();
    expect(
      tester.widget<CalendarPage>(find.byType(CalendarPage)).recordedDates,
      isNotEmpty,
    );
    await auth.signOut();
    await tester.pumpAndSettle();
    auth.accountId = 'another-user';
    await auth.signIn('another@example.com', 'password123');
    await tester.pumpAndSettle();
    expect(
      tester.widget<CalendarPage>(find.byType(CalendarPage)).recordedDates,
      isEmpty,
    );
  });
}

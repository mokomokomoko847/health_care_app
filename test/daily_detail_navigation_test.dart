import 'package:health_care_app/models/glucose_record.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:health_care_app/repositories/glucose_record_repository.dart';
import 'package:flutter/material.dart';
import 'support/fake_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/app_router.dart';
import 'package:health_care_app/pages/calendar_page.dart';
import 'package:health_care_app/pages/daily_detail_page.dart';

void main() {
  testWidgets('本人の保存済み記録を日別表示し、戻るとカレンダーへ戻る', (tester) async {
    final repository = FirestoreGlucoseRecordRepository(
      firestore: FakeFirebaseFirestore(),
    );
    final date = DateTime.now().subtract(const Duration(days: 1));
    for (var index = 0; index < 3; index++) {
      await repository.create(
        'test-user',
        'record-$index',
        GlucoseRecord(
          recordedAt: DateTime(date.year, date.month, date.day, 7 + index, 30),
          bloodSugarMgDl: 108 + index,
          mealTiming: MealTiming.beforeMeal,
          memo: index == 1 ? '昼食後に散歩' : '',
          photoPaths: [],
        ),
      );
    }
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: createAppRouter(
          repository: repository,
          auth: FakeAuthService(isSignedIn: true, isEmailVerified: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dayKey = ValueKey(
      'day-${yesterday.year}-${yesterday.month}-${yesterday.day}',
    );
    await tester.tap(find.byKey(dayKey));
    await tester.pumpAndSettle();

    expect(find.byType(DailyDetailPage), findsOneWidget);
    expect(find.text('3件の記録'), findsOneWidget);
    expect(find.text('07:30'), findsOneWidget);
    expect(find.text('108'), findsOneWidget);
    expect(find.text('訂正あり'), findsNothing);
    expect(find.text('昼食後に散歩'), findsOneWidget);

    await tester.tap(find.text('カレンダー'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
  });

  testWidgets('昨日以外の過去日は空状態を表示する', (tester) async {
    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: createAppRouter(
          repository: FirestoreGlucoseRecordRepository(
            firestore: FakeFirebaseFirestore(),
          ),
          auth: FakeAuthService(isSignedIn: true, isEmailVerified: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final twoDaysAgo = DateTime.now().subtract(const Duration(days: 2));
    final dayKey = ValueKey(
      'day-${twoDaysAgo.year}-${twoDaysAgo.month}-${twoDaysAgo.day}',
    );
    await tester.tap(find.byKey(dayKey));
    await tester.pumpAndSettle();

    expect(find.byType(DailyDetailPage), findsOneWidget);
    expect(find.text('この日の記録はありません'), findsOneWidget);
    expect(find.text('0件の記録'), findsOneWidget);
  });
}

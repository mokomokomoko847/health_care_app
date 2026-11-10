import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:health_care_app/repositories/glucose_record_repository.dart';
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'support/fake_auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:go_router/go_router.dart';

import 'package:health_care_app/main.dart';
import 'package:health_care_app/pages/calendar_page.dart';
import 'package:health_care_app/pages/login_page.dart';
import 'package:health_care_app/pages/record_input_page.dart';

void main() {
  testWidgets('記録入力画面の主要項目が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: RecordInputPage()));

    expect(find.text('記録入力'), findsOneWidget);
    expect(find.text('測定日時'), findsOneWidget);
    expect(find.text('血糖値'), findsAtLeastNWidgets(1));
    expect(find.text('測定タイミング'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('記録を保存'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('メモ'), findsOneWidget);
    expect(find.text('食事写真'), findsOneWidget);
    expect(find.text('記録を保存'), findsOneWidget);
  });

  testWidgets('カレンダーから新規記録入力へ遷移し、空の状態なら戻れる', (tester) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        repository: FirestoreGlucoseRecordRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'sample@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byKey(const ValueKey('authSubmit')));
    await tester.pumpAndSettle();

    expect(find.byType(CalendarPage), findsOneWidget);
    await tester.ensureVisible(find.text('記録入力'));
    await tester.tap(find.text('記録入力'));
    await tester.pumpAndSettle();

    expect(find.byType(RecordInputPage), findsOneWidget);
    expect(find.text('例：昼食後に散歩'), findsOneWidget);
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
  });

  testWidgets('未保存の入力から戻る際にキャンセルまたは破棄を選べる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const RecordInputPage(),
                  ),
                ),
                child: const Text('記録入力を開く'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('記録入力を開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123');
    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();

    expect(find.text('入力内容が保存されていません。戻りますか？'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordInputPage), findsOneWidget);
    expect(find.text('123'), findsOneWidget);

    await tester.tap(find.byTooltip('戻る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('戻る'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordInputPage), findsNothing);
  });

  testWidgets('ログイン成功でカレンダーへ進み、戻る操作では終了確認を表示する', (tester) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        repository: FirestoreGlucoseRecordRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      'sample@example.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'password123');
    await tester.tap(find.byKey(const ValueKey('authSubmit')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
    final router = GoRouter.of(tester.element(find.byType(CalendarPage)));
    expect(router.routeInformationProvider.value.uri.path, '/calendar');
    expect(router.canPop(), isFalse);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('アプリを終了しますか？'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);

    await tester.tap(find.text('ログアウト'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginPage), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, '/login');
    expect(router.canPop(), isFalse);
    expect(find.byType(CalendarPage), findsNothing);
    for (final field in tester.widgetList<TextFormField>(
      find.byType(TextFormField),
    )) {
      expect(field.controller!.text, isEmpty);
    }
  });

  testWidgets('モード切り替えはメールを保持し、パスワードとエラーを消す', (tester) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        repository: FirestoreGlucoseRecordRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'sample@example.com');
    await tester.enterText(fields.at(1), 'password123');
    await tester.tap(find.byKey(const ValueKey('registerTab')));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'sample@example.com',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      isEmpty,
    );
    expect(find.text('パスワードを忘れた方'), findsNothing);
    await tester.ensureVisible(find.byKey(const ValueKey('authSubmit')));
    await tester.tap(find.byKey(const ValueKey('authSubmit')));
    await tester.pumpAndSettle();
    expect(find.text('パスワードを入力してください'), findsOneWidget);
    await tester.ensureVisible(find.byKey(const ValueKey('loginTab')));
    await tester.tap(find.byKey(const ValueKey('loginTab')));
    await tester.pumpAndSettle();
    expect(find.text('パスワードを入力してください'), findsNothing);
    expect(
      tester.widget<TextFormField>(fields.at(0)).controller!.text,
      'sample@example.com',
    );
    expect(
      tester.widget<TextFormField>(fields.at(1)).controller!.text,
      isEmpty,
    );
    expect(find.text('パスワードを忘れた方'), findsOneWidget);
  });

  testWidgets('パスワードを表示・非表示に切り替えられる', (tester) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        repository: FirestoreGlucoseRecordRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byType(TextField).last;
    expect(tester.widget<TextField>(field).obscureText, isTrue);
    await tester.tap(find.byTooltip('パスワードを表示'));
    await tester.pump();
    expect(tester.widget<TextField>(field).obscureText, isFalse);
    await tester.tap(find.byTooltip('パスワードを隠す'));
    await tester.pump();
    expect(tester.widget<TextField>(field).obscureText, isTrue);
  });

  testWidgets('ログインで不正な形式を拒否する', (tester) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        repository: FirestoreGlucoseRecordRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'mock');
    await tester.enterText(fields.at(1), '1');
    await tester.tap(find.byKey(const ValueKey('authSubmit')));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsNothing);
    expect(find.text('メールアドレスの形式を確認してください'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets('新規登録ではパスワード条件を確認し、確認待ちへ進む', (tester) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        repository: FirestoreGlucoseRecordRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('registerTab')));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'sample@example.com');
    await tester.enterText(fields.at(1), 'abc1234');
    final submit = find.byKey(const ValueKey('authSubmit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('8文字以上で、英字と数字をそれぞれ含めてください'), findsOneWidget);
    await tester.enterText(fields.at(1), 'abc12345');
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('確認が完了しました'), findsOneWidget);
    expect(find.byType(CalendarPage), findsNothing);
    expect(find.byType(RecordInputPage), findsNothing);
  });

  testWidgets('パスワード再設定のメール入力画面を開く', (tester) async {
    await tester.pumpWidget(
      RakuchinReportApp(
        repository: FirestoreGlucoseRecordRepository(
          firestore: FakeFirebaseFirestore(),
        ),
        auth: FakeAuthService(),
      ),
    );
    await tester.pumpAndSettle();
    final helper = find.text('パスワードを忘れた方');
    await tester.ensureVisible(helper);
    await tester.tap(helper);
    await tester.pumpAndSettle();
    expect(find.text('再設定メールを送信'), findsOneWidget);
  });

  testWidgets('小さい画面と文字拡大でもスクロールして操作できる', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: RakuchinReportApp(
          repository: FirestoreGlucoseRecordRepository(
            firestore: FakeFirebaseFirestore(),
          ),
          auth: FakeAuthService(),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('registerTab')));
    await tester.pumpAndSettle();
    final submit = find.byKey(const ValueKey('authSubmit'));
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('メールアドレスを入力してください'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

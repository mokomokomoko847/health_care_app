import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:health_care_app/app_router.dart';
import 'package:health_care_app/main.dart';
import 'package:health_care_app/pages/calendar_page.dart';
import 'package:health_care_app/pages/email_verification_page.dart';
import 'package:health_care_app/pages/login_page.dart';
import 'package:health_care_app/pages/password_reset_page.dart';

import 'support/fake_auth_service.dart';

void main() {
  Future<void> open(WidgetTester tester, FakeAuthService auth) async {
    addTearDown(auth.dispose);
    await tester.pumpWidget(RakuchinReportApp(auth: auth));
    await tester.pumpAndSettle();
  }

  testWidgets('復元済みの確認済みセッションではカレンダーから開始する', (tester) async {
    await open(
      tester,
      FakeAuthService(isSignedIn: true, isEmailVerified: true),
    );
    expect(find.byType(CalendarPage), findsOneWidget);
    expect(find.byType(LoginPage), findsNothing);
  });

  for (final signedIn in [false, true]) {
    testWidgets('未認証または未確認では保護ルートへの直接遷移を拒否する signedIn=$signedIn', (
      tester,
    ) async {
      final auth = FakeAuthService(isSignedIn: signedIn);
      final router = createAppRouter(auth: auth);
      addTearDown(router.dispose);
      addTearDown(auth.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      for (final path in ['/calendar', '/daily-detail', '/record-input']) {
        router.go(path);
        await tester.pumpAndSettle();
        expect(
          router.routeInformationProvider.value.uri.path,
          signedIn ? '/verify-email' : '/login',
        );
      }
    });
  }

  testWidgets('未確認・再送・確認完了・ログアウトが認証状態に従って動く', (tester) async {
    final auth = FakeAuthService(isSignedIn: true);
    await open(tester, auth);
    await tester.tap(find.text('確認が完了しました'));
    await tester.pumpAndSettle();
    expect(find.text('メールアドレスの確認が完了していません。'), findsOneWidget);
    await tester.tap(find.text('確認メールを再送する'));
    await tester.pumpAndSettle();
    expect(auth.resendCalls, 1);
    expect(find.text('確認メールを再送しました。'), findsOneWidget);
    auth.verifiedOnReload = true;
    await tester.tap(find.text('確認が完了しました'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
    await tester.tap(find.text('ログアウト'));
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isFalse);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('ログアウト失敗ではカレンダーに留まりエラーを表示する', (tester) async {
    final auth = FakeAuthService(isSignedIn: true, isEmailVerified: true)
      ..failure = FirebaseAuthException(code: 'network-request-failed');
    await open(tester, auth);
    await tester.tap(find.text('ログアウト'));
    await tester.pumpAndSettle();
    expect(find.byType(CalendarPage), findsOneWidget);
    expect(auth.isSignedIn, isTrue);
    expect(find.textContaining('通信できませんでした'), findsOneWidget);
  });

  testWidgets('認証中は重複送信とモード変更を防ぎ、失敗後は入力を保持する', (tester) async {
    final pending = Completer<void>();
    final auth = FakeAuthService()
      ..pending = pending
      ..failure = FirebaseAuthException(code: 'invalid-credential');
    await open(tester, auth);
    await tester.enterText(
      find.byType(TextFormField).at(0),
      ' sample@example.com ',
    );
    await tester.enterText(find.byType(TextFormField).at(1), ' password123 ');
    final submit = find.byKey(const ValueKey('authSubmit'));
    await tester.tap(submit);
    await tester.pump();
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('registerTab')))
          .onPressed,
      isNull,
    );
    expect(auth.signInCalls, 1);
    expect(auth.submittedEmail, 'sample@example.com');
    expect(auth.submittedPassword, ' password123 ');
    pending.complete();
    await tester.pumpAndSettle();
    expect(find.text('メールアドレスまたはパスワードが正しくありません。'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).at(1))
          .controller!
          .text,
      ' password123 ',
    );
  });

  testWidgets('確認メール送信失敗を確認待ち画面に表示し、確認取得失敗でも留まる', (tester) async {
    final auth = FakeAuthService(isSignedIn: true)
      ..verificationError = '確認メールを送信できませんでした。'
      ..failure = FirebaseAuthException(code: 'network-request-failed');
    await open(tester, auth);
    expect(find.text('確認メールを送信できませんでした。'), findsOneWidget);
    await tester.tap(find.text('確認が完了しました'));
    await tester.pumpAndSettle();
    expect(find.byType(EmailVerificationPage), findsOneWidget);
    expect(find.textContaining('通信できませんでした'), findsOneWidget);
  });

  testWidgets('確認待ちから戻ると認証を解除する', (tester) async {
    final auth = FakeAuthService(isSignedIn: true);
    await open(tester, auth);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(auth.isSignedIn, isFalse);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('再設定メール送信は空欄を拒否し、失敗後の再試行で送信完了を表示する', (tester) async {
    final auth = FakeAuthService()
      ..failure = FirebaseAuthException(code: 'network-request-failed');
    await tester.pumpWidget(MaterialApp(home: PasswordResetPage(auth: auth)));
    await tester.tap(find.text('再設定メールを送信'));
    await tester.pumpAndSettle();
    expect(auth.resetCalls, 0);
    await tester.enterText(find.byType(TextFormField), 'sample@example.com');
    await tester.tap(find.text('再設定メールを送信'));
    await tester.pumpAndSettle();
    expect(find.textContaining('通信できませんでした'), findsOneWidget);
    auth.failure = null;
    await tester.tap(find.text('再設定メールを送信'));
    await tester.pumpAndSettle();
    expect(find.textContaining('再設定メールが届きます'), findsOneWidget);
  });

  testWidgets('再設定コード検証後だけ新しいパスワードを入力でき、成功後も完了画面に留まる', (tester) async {
    final auth = FakeAuthService();
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordResetPage(auth: auth, code: 'test-code'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).last, 'abc1234');
    await tester.tap(find.text('パスワードを再設定'));
    await tester.pumpAndSettle();
    expect(auth.submittedPassword, isNull);
    await tester.enterText(find.byType(TextFormField).last, 'abc12345');
    await tester.tap(find.text('パスワードを再設定'));
    await tester.pumpAndSettle();
    expect(auth.submittedPassword, 'abc12345');
    expect(find.textContaining('パスワードを再設定しました'), findsOneWidget);
  });

  testWidgets('期限切れコードではパスワードを設定できない', (tester) async {
    final auth = FakeAuthService()
      ..failure = FirebaseAuthException(code: 'expired-action-code');
    await tester.pumpWidget(
      MaterialApp(
        home: PasswordResetPage(auth: auth, code: 'expired'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('有効期限が切れています'), findsOneWidget);
    expect(find.text('パスワードを再設定'), findsNothing);
  });

  testWidgets('未ログインでも受信した再設定リンクを開ける', (tester) async {
    final auth = FakeAuthService();
    await open(tester, auth);
    final router = GoRouter.of(tester.element(find.byType(LoginPage)));
    router.go('/auth-action?mode=resetPassword&oobCode=test-code');
    await tester.pumpAndSettle();
    expect(find.byType(PasswordResetPage), findsOneWidget);
    expect(find.text('新しいパスワード'), findsOneWidget);
    router.go('/auth-action?mode=unknown&oobCode=test-code');
    await tester.pumpAndSettle();
    expect(find.text('無効なリンク'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'pages/calendar_page.dart';
import 'pages/daily_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/record_input_page.dart';
import 'models/mock_daily_records.dart';
import 'services/auth_service.dart';
import 'pages/email_verification_page.dart';
import 'pages/password_reset_page.dart';

/// 認証状態の変更時に保護対象のルートを再評価する。
GoRouter createAppRouter({required AuthService auth}) {
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final mockRecordDate = MockDailyRecords.sampleDate(normalizedToday);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: auth,
    redirect: (context, state) {
      final path = state.uri.path;
      // メールのコードはセッションの有無に関係なくFirebaseで検証する。
      if (path == '/auth-action') return null;
      if (!auth.isReady) return path == '/loading' ? null : '/loading';
      if (!auth.isSignedIn) {
        return path == '/login' || path == '/password-reset' ? null : '/login';
      }
      if (!auth.isEmailVerified) {
        return path == '/verify-email' ? null : '/verify-email';
      }
      if (path == '/login' ||
          path == '/loading' ||
          path == '/verify-email' ||
          path == '/password-reset') {
        return '/calendar';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/loading',
        builder: (context, state) => Scaffold(
          body: Center(
            child: auth.initializationError == null
                ? const CircularProgressIndicator()
                : Text(auth.initializationError!),
          ),
        ),
      ),
      GoRoute(
        path: '/verify-email',
        builder: (context, state) => EmailVerificationPage(auth: auth),
      ),
      GoRoute(
        path: '/password-reset',
        builder: (context, state) => PasswordResetPage(
          auth: auth,
          initialEmail: state.extra as String? ?? '',
        ),
      ),
      GoRoute(
        path: '/auth-action',
        builder: (context, state) {
          final code = state.uri.queryParameters['oobCode'];
          final mode = state.uri.queryParameters['mode'];
          if (code == null ||
              code.isEmpty ||
              (mode != 'resetPassword' && mode != 'verifyEmail')) {
            return Scaffold(
              appBar: AppBar(title: const Text('無効なリンク')),
              body: Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('リンクが無効です。ログイン画面へ戻る'),
                ),
              ),
            );
          }
          if (mode == 'verifyEmail') {
            return EmailActionPage(key: ValueKey(code), auth: auth, code: code);
          }
          return PasswordResetPage(key: ValueKey(code), auth: auth, code: code);
        },
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          auth: auth,
          onPasswordReset: (email) =>
              context.push('/password-reset', extra: email),
        ),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => CalendarPage(
          today: normalizedToday,
          recordedDates: {mockRecordDate},
          onDateSelected: (date) => context.push('/daily-detail', extra: date),
          onCreateRecord: () => context.push('/record-input'),
          onLogout: () async {
            try {
              await auth.signOut();
            } catch (error) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(authErrorMessage(error))));
            }
          },
        ),
      ),
      GoRoute(
        path: '/daily-detail',
        builder: (context, state) {
          final selectedDate = state.extra as DateTime? ?? mockRecordDate;
          return DailyDetailPage(
            date: selectedDate,
            records: MockDailyRecords.forDate(selectedDate, normalizedToday),
          );
        },
      ),
      GoRoute(
        path: '/record-input',
        builder: (context, state) => const RecordInputPage(),
      ),
    ],
  );
}

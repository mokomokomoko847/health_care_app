import 'package:go_router/go_router.dart';

import 'pages/calendar_page.dart';
import 'pages/daily_detail_page.dart';
import 'pages/login_page.dart';
import 'pages/record_input_page.dart';
import 'models/mock_daily_records.dart';

/// 現段階は認証せず画面をつなぐモック。Firebase認証の接続は後続で行う。
GoRouter createAppRouter() {
  final today = DateTime.now();
  final normalizedToday = DateTime(today.year, today.month, today.day);
  final mockRecordDate = MockDailyRecords.sampleDate(normalizedToday);

  return GoRouter(
    initialLocation: '/login',
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => LoginPage(
          // goで履歴を置き換え、端末の戻る操作でログインへ戻さない。
          onLogin: () => context.go('/calendar'),
        ),
      ),
      GoRoute(
        path: '/calendar',
        builder: (context, state) => CalendarPage(
          today: normalizedToday,
          recordedDates: {mockRecordDate},
          onDateSelected: (date) => context.push('/daily-detail', extra: date),
          onCreateRecord: () => context.push('/record-input'),
          onLogout: () => context.go('/login'),
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

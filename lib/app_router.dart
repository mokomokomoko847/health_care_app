import 'package:go_router/go_router.dart';

import 'pages/calendar_page.dart';
import 'pages/login_page.dart';

/// 現段階は認証せず画面をつなぐモック。Firebase認証の接続は後続で行う。
GoRouter createAppRouter() {
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
        builder: (context, state) =>
            CalendarPage(onLogout: () => context.go('/login')),
      ),
    ],
  );
}

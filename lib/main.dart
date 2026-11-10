import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app_router.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const RakuchinReportApp());
}

class RakuchinReportApp extends StatefulWidget {
  const RakuchinReportApp({super.key, this.auth});

  final AuthService? auth;

  @override
  State<RakuchinReportApp> createState() => _RakuchinReportAppState();
}

class _RakuchinReportAppState extends State<RakuchinReportApp> {
  // 再描画のたびにルーターを作り直さず、アプリの生存期間中保持する。
  late final _auth = widget.auth ?? FirebaseAuthService();
  late final _router = createAppRouter(auth: _auth);

  @override
  void dispose() {
    _router.dispose();
    if (widget.auth == null) _auth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: '楽ちん報告アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F7A8C)),
      ),
      routerConfig: _router,
    );
  }
}

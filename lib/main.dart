import 'package:flutter/material.dart';

import 'app_router.dart';

void main() {
  runApp(const RakuchinReportApp());
}

class RakuchinReportApp extends StatefulWidget {
  const RakuchinReportApp({super.key});

  @override
  State<RakuchinReportApp> createState() => _RakuchinReportAppState();
}

class _RakuchinReportAppState extends State<RakuchinReportApp> {
  // 再描画のたびにルーターを作り直さず、アプリの生存期間中保持する。
  late final _router = createAppRouter();

  @override
  void dispose() {
    _router.dispose();
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

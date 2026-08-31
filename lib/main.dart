import 'package:flutter/material.dart';

import 'pages/record_input_page.dart';

void main() {
  runApp(const RakuchinReportApp());
}

class RakuchinReportApp extends StatelessWidget {
  const RakuchinReportApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '楽ちん報告アプリ',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1F7A8C)),
      ),
      home: const RecordInputPage(),
    );
  }
}

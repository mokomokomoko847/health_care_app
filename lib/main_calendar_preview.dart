import 'package:flutter/material.dart';

import 'pages/calendar_page.dart';

/// UI確認専用の起動口。本番のログイン処理や保存データには接続しない。
void main() {
  runApp(const CalendarPreviewApp());
}

class CalendarPreviewApp extends StatelessWidget {
  const CalendarPreviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return MaterialApp(
      title: 'カレンダー プレビュー',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1D4ED8)),
      ),
      builder: (context, child) => Banner(
        message: 'UIプレビュー',
        location: BannerLocation.bottomEnd,
        child: child!,
      ),
      home: CalendarPage(
        recordedDates: {
          for (final day in [10, 12, 14])
            if (day <= today.day) DateTime(today.year, today.month, day),
        },
      ),
    );
  }
}

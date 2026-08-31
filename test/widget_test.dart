// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_care_app/main.dart';

void main() {
  testWidgets('記録入力画面の主要項目が表示される', (WidgetTester tester) async {
    await tester.pumpWidget(const RakuchinReportApp());

    expect(find.text('血糖記録入力'), findsOneWidget);
    expect(find.text('日時'), findsOneWidget);
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
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/main_calendar_preview.dart';
import 'package:health_care_app/pages/calendar_page.dart';

void main() {
  final today = DateTime(2026, 10, 22, 15);
  Finder day(int day) => find.byKey(ValueKey('day-2026-10-$day'));

  testWidgets('今日と記録ありの日を識別し、時刻付きの記録も同じ日として扱う', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(
          today: today,
          recordedDates: {
            DateTime(2026, 10, 10, 9),
            DateTime(2026, 10, 22, 18),
          },
        ),
      ),
    );
    expect(find.text('2026年10月'), findsOneWidget);
    expect(find.text('今日（10月22日）'), findsOneWidget);
    expect(find.bySemanticsLabel('2026年10月10日、記録あり'), findsOneWidget);
    expect(find.bySemanticsLabel('2026年10月22日、今日、記録あり'), findsOneWidget);
    expect(find.bySemanticsLabel('2026年10月11日、記録なし'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('今日と過去の空の日も選択でき、未来日は選択できない', (tester) async {
    final selected = <DateTime>[];
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(today: today, onDateSelected: selected.add),
      ),
    );
    await tester.tap(day(1));
    await tester.tap(day(22));
    expect(tester.widget<TextButton>(day(23)).onPressed, isNull);
    await tester.tap(day(23));
    expect(selected, [DateTime(2026, 10, 1), DateTime(2026, 10, 22)]);
    expect(find.byKey(const ValueKey('day-2026-9-30')), findsNothing);
  });

  testWidgets('年をまたいで月を切り替えられる', (tester) async {
    await tester.pumpWidget(
      MaterialApp(home: CalendarPage(today: DateTime(2026, 12, 31))),
    );
    await tester.tap(find.byTooltip('翌月へ'));
    await tester.pump();
    expect(find.text('2027年1月'), findsOneWidget);
    expect(
      tester
          .widget<TextButton>(find.byKey(const ValueKey('day-2027-1-1')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('前月へ'));
    await tester.pump();
    expect(find.text('2026年12月'), findsOneWidget);
  });

  testWidgets('親から記録日が更新されたら表示へ反映する', (tester) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(
          today: today,
          recordedDates: {DateTime(2026, 10, 10)},
        ),
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(
          today: today,
          recordedDates: {DateTime(2026, 10, 12)},
        ),
      ),
    );
    expect(find.bySemanticsLabel('2026年10月10日、記録なし'), findsOneWidget);
    expect(find.bySemanticsLabel('2026年10月12日、記録あり'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('接続済みの記録入力とログアウトの操作を呼び出す', (tester) async {
    var createCount = 0;
    var logoutCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: CalendarPage(
          today: today,
          onCreateRecord: () => createCount++,
          onLogout: () => logoutCount++,
        ),
      ),
    );
    await tester.tap(find.text('ログアウト'));
    await tester.ensureVisible(find.text('記録入力'));
    await tester.tap(find.text('記録入力'));
    expect(createCount, 1);
    expect(logoutCount, 1);
  });

  testWidgets('未接続の操作は案内を表示し、画面に留まる', (tester) async {
    await tester.pumpWidget(MaterialApp(home: CalendarPage(today: today)));
    await tester.tap(day(10));
    await tester.pumpAndSettle();
    expect(find.text('日別詳細画面と記録データの取得はまだ接続されていません。'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('ログアウト'));
    await tester.pumpAndSettle();
    expect(find.text('Firebase認証が未接続のため、ログアウト処理は実行できません。'), findsOneWidget);
    await tester.tap(find.text('閉じる'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('記録入力'));
    await tester.tap(find.text('記録入力'));
    await tester.pumpAndSettle();
    expect(find.text('記録入力画面への接続はまだ実装されていません。'), findsOneWidget);
    expect(find.byType(CalendarPage), findsOneWidget);
  });

  testWidgets('戻る操作で終了確認し、キャンセル時は留まり終了時だけシステムへ通知する', (tester) async {
    final calls = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        calls.add(call);
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await tester.pumpWidget(MaterialApp(home: CalendarPage(today: today)));
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('アプリを終了しますか？'), findsOneWidget);
    await tester.tap(find.text('キャンセル'));
    await tester.pumpAndSettle();
    expect(
      calls.where((call) => call.method == 'SystemNavigator.pop'),
      isEmpty,
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('終了'));
    await tester.pumpAndSettle();
    expect(
      calls.where((call) => call.method == 'SystemNavigator.pop'),
      hasLength(1),
    );
  });

  testWidgets('小さい画面と文字拡大でも6週表示と記録入力を操作できる', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var createCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(1.5)),
          child: child!,
        ),
        home: CalendarPage(
          today: DateTime(2026, 3, 31),
          onCreateRecord: () => createCount++,
        ),
      ),
    );
    await tester.ensureVisible(find.text('記録入力'));
    await tester.tap(find.text('記録入力'));
    await tester.pump();
    expect(createCount, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('プレビュー起動口からサンプル画面を表示する', (tester) async {
    await tester.pumpWidget(const CalendarPreviewApp());
    expect(find.byType(CalendarPage), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Banner && widget.message == 'UIプレビュー',
      ),
      findsOneWidget,
    );
  });
}

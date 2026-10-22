import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/calendar_month.dart';

/// カレンダーの表示と操作を担当する。認証・データ取得・遷移は接続側で扱う。
class CalendarPage extends StatefulWidget {
  const CalendarPage({
    super.key,
    this.today,
    this.recordedDates = const {},
    this.onDateSelected,
    this.onCreateRecord,
    this.onLogout,
  });

  final DateTime? today;
  final Set<DateTime> recordedDates;
  final ValueChanged<DateTime>? onDateSelected;
  final VoidCallback? onCreateRecord;
  final VoidCallback? onLogout;

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with WidgetsBindingObserver {
  static const _primary = Color(0xFF0037B0);
  static const _blue = Color(0xFF1D4ED8);
  static const _background = Color(0xFFF9F9FF);
  static const _pale = Color(0xFFF1F3FF);
  static const _ink = Color(0xFF141B2B);
  static const _secondary = Color(0xFF585F67);

  late CalendarMonth _month;
  bool _exitDialogOpen = false;

  DateTime get _today => CalendarMonth.dateOnly(widget.today ?? DateTime.now());

  @override
  void initState() {
    super.initState();
    _month = CalendarMonth(_today);
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 翌日にアプリへ戻った際も、今日の目印と未来日の判定を更新する。
    if (state == AppLifecycleState.resumed) setState(() {});
  }

  void _changeMonth(int offset) {
    setState(() => _month = _month.shift(offset));
  }

  Future<void> _showUnavailable(String title, String message) {
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmExit() async {
    if (_exitDialogOpen) return;
    _exitDialogOpen = true;
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('アプリを終了しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('終了'),
          ),
        ],
      ),
    );
    _exitDialogOpen = false;
    if (shouldExit == true && mounted) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final recordedDates = widget.recordedDates
        .map(CalendarMonth.dateOnly)
        .toSet();
    return Theme(
      data: theme.copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: _blue,
          primary: _primary,
          surface: Colors.white,
          onSurface: _ink,
        ),
        textTheme: theme.textTheme.apply(bodyColor: _ink, displayColor: _ink),
      ),
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _confirmExit();
        },
        child: Scaffold(
          backgroundColor: _background,
          appBar: _buildAppBar(),
          body: SafeArea(
            top: false,
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMonthNavigation(),
                      const SizedBox(height: 12),
                      _buildCalendar(recordedDates),
                      const SizedBox(height: 16),
                      _buildLegend(),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed:
                            widget.onCreateRecord ??
                            () => _showUnavailable(
                              '記録入力',
                              '記録入力画面への接続はまだ実装されていません。',
                            ),
                        style: FilledButton.styleFrom(
                          backgroundColor: _blue,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: const Text('記録入力'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      toolbarHeight: 64,
      titleSpacing: 20,
      title: const Text(
        'Calendar',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: _ink,
        ),
      ),
      actions: [
        TextButton(
          onPressed:
              widget.onLogout ??
              () => _showUnavailable(
                'ログアウト',
                'Firebase認証が未接続のため、ログアウト処理は実行できません。',
              ),
          style: TextButton.styleFrom(
            foregroundColor: _primary,
            minimumSize: const Size(48, 44),
            textStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          child: const Text('ログアウト'),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 8, right: 20),
          child: CircleAvatar(
            radius: 16,
            backgroundColor: _primary,
            child: Icon(Icons.person_outline, color: Colors.white, size: 18),
          ),
        ),
      ],
    );
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
    ),
    child: child,
  );

  Widget _buildMonthNavigation() {
    return _card(
      Row(
        children: [
          _buildMonthButton('前月へ', Icons.chevron_left, -1),
          Expanded(
            child: Text(
              _month.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          _buildMonthButton('翌月へ', Icons.chevron_right, 1),
        ],
      ),
    );
  }

  Widget _buildMonthButton(String label, IconData icon, int offset) {
    return IconButton(
      tooltip: label,
      onPressed: () => _changeMonth(offset),
      style: IconButton.styleFrom(
        backgroundColor: _pale,
        foregroundColor: _ink,
        minimumSize: const Size(44, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Icon(icon, size: 20),
    );
  }

  Widget _buildCalendar(Set<DateTime> recordedDates) {
    final days = _month.days;
    return _card(
      Column(
        children: [
          Row(
            children: [
              for (final weekday in ['月', '火', '水', '木', '金', '土', '日'])
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(
                      weekday,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 14,
                        color: _secondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              final cellWidth = (constraints.maxWidth - 24) / 7;
              // 狭い端末や文字拡大時にも、日付と今日の目印が収まる高さを確保する。
              final cellHeight = math.max(
                cellWidth,
                math.max(44.0, MediaQuery.textScalerOf(context).scale(16) + 24),
              );
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: EdgeInsets.zero,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  mainAxisExtent: cellHeight,
                ),
                itemCount: days.length,
                itemBuilder: (context, index) =>
                    _buildDay(days[index], recordedDates.contains(days[index])),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDay(DateTime date, bool hasRecord) {
    if (!_month.contains(date)) {
      return ExcludeSemantics(
        child: Center(
          child: Text(
            '${date.day}',
            style: const TextStyle(fontSize: 14, color: Color(0xFFC4C5D7)),
          ),
        ),
      );
    }
    final isFuture = date.isAfter(_today);
    final isToday = date == _today;
    final showRecord = hasRecord && !isFuture;
    final foreground = isFuture
        ? const Color(0xFF747686)
        : showRecord
        ? Colors.white
        : _ink;
    final label =
        '${date.year}年${date.month}月${date.day}日'
        '${isToday ? '、今日' : ''}、${isFuture
            ? '未来の日付、選択できません'
            : showRecord
            ? '記録あり'
            : '記録なし'}';
    return Semantics(
      label: label,
      button: true,
      enabled: !isFuture,
      child: TextButton(
        key: ValueKey('day-${date.year}-${date.month}-${date.day}'),
        onPressed: isFuture
            ? null
            : () {
                if (widget.onDateSelected != null) {
                  widget.onDateSelected!(date);
                } else {
                  _showUnavailable(
                    '${date.month}月${date.day}日の記録',
                    '日別詳細画面と記録データの取得はまだ接続されていません。',
                  );
                }
              },
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          backgroundColor: isFuture
              ? _pale
              : showRecord
              ? _blue
              : Colors.white,
          foregroundColor: foreground,
          disabledBackgroundColor: _pale,
          disabledForegroundColor: foreground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isToday && !showRecord
                ? const BorderSide(color: _blue, width: 2)
                : BorderSide.none,
          ),
        ),
        child: ExcludeSemantics(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${date.day}',
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: showRecord ? FontWeight.bold : FontWeight.w500,
                  ),
                ),
              ),
              if (isToday) ...[
                const SizedBox(height: 4),
                _dot(showRecord ? Colors.white : _blue, 6),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _dot(Color color, double size) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget _buildLegend() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 24,
            runSpacing: 8,
            children: [
              _legendItem(false, '記録あり'),
              _legendItem(true, '今日（${_today.month}月${_today.day}日）'),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            '※未来の日付は選択できません',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
          const SizedBox(height: 4),
          const Text(
            '※日付をタップすると日別の詳細を確認できます',
            style: TextStyle(fontSize: 14, color: _secondary),
          ),
        ],
      ),
    );
  }

  Widget _legendItem(bool today, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: today ? Colors.white : _blue,
          border: today ? Border.all(color: _blue) : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: today ? Center(child: _dot(_blue, 4)) : null,
      ),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 14)),
    ],
  );
}

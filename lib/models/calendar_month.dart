/// 月曜始まりの月表示に必要な日付計算を、画面から独立して扱う。
class CalendarMonth {
  CalendarMonth(DateTime date) : firstDay = DateTime(date.year, date.month);

  final DateTime firstDay;

  String get label => '${firstDay.year}年${firstDay.month}月';

  CalendarMonth shift(int months) =>
      CalendarMonth(DateTime(firstDay.year, firstDay.month + months));

  List<DateTime> get days {
    final leadingDays = firstDay.weekday - DateTime.monday;
    final daysInMonth = DateTime(firstDay.year, firstDay.month + 1, 0).day;
    final cellCount = ((leadingDays + daysInMonth + 6) ~/ 7) * 7;
    // Durationを足さず日付のコンストラクタを使い、夏時間のある地域にも対応する。
    return List.generate(
      cellCount,
      (index) =>
          DateTime(firstDay.year, firstDay.month, 1 - leadingDays + index),
    );
  }

  bool contains(DateTime date) =>
      date.year == firstDay.year && date.month == firstDay.month;

  static DateTime dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}

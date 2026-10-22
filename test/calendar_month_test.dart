import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/models/calendar_month.dart';

void main() {
  test('2026年10月は月曜始まりで前後の月を含めた5週を表示する', () {
    final month = CalendarMonth(DateTime(2026, 10, 22));
    expect(month.label, '2026年10月');
    expect(month.days.length, 35);
    expect(month.days.first, DateTime(2026, 9, 28));
    expect(month.days.last, DateTime(2026, 11, 1));
    expect(month.contains(DateTime(2026, 10, 1)), isTrue);
    expect(month.contains(DateTime(2026, 9, 30)), isFalse);
    expect(month.contains(DateTime(2025, 10, 1)), isFalse);
  });

  test('月曜始まりの28日月は4週になる', () {
    final days = CalendarMonth(DateTime(2027, 2)).days;
    expect(days.length, 28);
    expect(days.first, DateTime(2027, 2, 1));
    expect(days.last, DateTime(2027, 2, 28));
  });

  test('日曜始まりの31日月は6週になる', () {
    final days = CalendarMonth(DateTime(2026, 3)).days;
    expect(days.length, 42);
    expect(days.first, DateTime(2026, 2, 23));
    expect(days.last, DateTime(2026, 4, 5));
  });

  test('うるう年と平年の2月を扱う', () {
    final leapMonth = CalendarMonth(DateTime(2024, 2));
    final normalMonth = CalendarMonth(DateTime(2025, 2));
    expect(leapMonth.days.where(leapMonth.contains).length, 29);
    expect(normalMonth.days.where(normalMonth.contains).length, 28);
  });

  test('前月・翌月への移動で年をまたげる', () {
    final december = CalendarMonth(DateTime(2026, 12, 31));
    expect(december.shift(1).firstDay, DateTime(2027, 1));
    expect(december.shift(1).shift(-1).firstDay, DateTime(2026, 12));
    expect(
      CalendarMonth(DateTime(2026, 1)).shift(-1).firstDay,
      DateTime(2025, 12),
    );
  });

  test('時刻を取り除いて日付単位で扱える', () {
    expect(
      CalendarMonth.dateOnly(DateTime(2026, 10, 22, 23, 59)),
      DateTime(2026, 10, 22),
    );
  });
}

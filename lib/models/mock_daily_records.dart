import 'glucose_record.dart';

class MockDailyRecord {
  const MockDailyRecord({
    required this.record,
    this.hasCorrectionHistory = false,
  });

  final GlucoseRecord record;
  final bool hasCorrectionHistory;
}

class MockDailyRecords {
  static DateTime sampleDate(DateTime today) {
    final normalizedToday = DateTime(today.year, today.month, today.day);
    return normalizedToday.subtract(const Duration(days: 1));
  }

  static List<MockDailyRecord> forDate(DateTime date, DateTime today) {
    final selectedDate = DateTime(date.year, date.month, date.day);
    if (selectedDate != sampleDate(today)) return const [];

    DateTime at(int hour, int minute) => DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      hour,
      minute,
    );

    return [
      MockDailyRecord(
        record: GlucoseRecord(
          recordedAt: at(7, 30),
          bloodSugarMgDl: 108,
          mealTiming: MealTiming.beforeMeal,
          memo: '',
          photoPaths: const [],
        ),
      ),
      MockDailyRecord(
        record: GlucoseRecord(
          recordedAt: at(12, 30),
          bloodSugarMgDl: 142,
          mealTiming: MealTiming.afterMeal,
          memo: '昼食後に散歩',
          photoPaths: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCNkkF3Zu5k3NQwp0KwcGnL05bOHiwHDd58WXe7l7DzDMwSNP5mYpYRh9VaaLdAvJvXqj7y_-NJOkP0po8hvwBzgutrvqKeGNa7Y1PmBeRr5ue-K4Wq-hHXnh06piP1fBbfMDtxFpReuzORQaul2RyCNnAgGeshZ3Vl7Rw42s8HqP6Wvi_80enOTpmjxfZA9GJiWmQTG_WlpgmE3WSW3d3MFN6ix8uRduKwVUJbRC-dbr6F1FXp3JFieQ',
          ],
        ),
        hasCorrectionHistory: true,
      ),
      MockDailyRecord(
        record: GlucoseRecord(
          recordedAt: at(19, 0),
          bloodSugarMgDl: 136,
          mealTiming: MealTiming.afterMeal,
          memo: '夕食を記録',
          photoPaths: const [
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAZavGDcKRcrU-C8QK18PKV3gOcgBZkII1IFR93ocjtRRkBFULj92Lq1-aRn3eJ_7vG-qbuanJdCIby9unnmwcZtFPrn_f4J_QlvyrQU7Z7Zu4b3YquS5SVEOEf_nqRqQMZmV_lESwifECRyzrVbGNpBed2zziWVEdKm2CZdCwWtwM6Gh96Ujlh5I4DJDaMJzRkXX8xYkj6ifeR-agPCaPaYIXtPayuRV20f6RIemZESl6e2W1mCdAF2w',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCza0GIXGHmLfR91ym23itPg-uJ510LanrzyK8bXwkZjYmvf2zHibJpUdWi5n5yl0YPMCnoeGCIvwM56EQg8I1H7erZq8f25q20wDVoKVgqyXYwtnR9842ng-1py8qnUnS3EIMETJg-RpB0YIDyhRxfUWUY1WZLNny1qiE4WOr73J8BFDMWSQOC_xP1udr-pDmF5XuD4mgyXYbSbNQUKSzOxERcuge-SyeBtWRvccb7pngjXfeK6n-R-Q',
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCAeb0k8wLSaH5kxlznKe1a8Q3qPqny3vWm3Nr35_gXjzNZRDFLz5yJcYGdmENH9SkPzREROvJlwM2aBpE1xBePmGbOKUWN5RkcShzQMv3Mi9I131ZY3r0Wkziho2i5R8T0bt6o9ckwxWRH-3jOHS_X_u0Wef6wqZ1r6JvXgoj-2wzYXmvv4QM3GVNGvDuMd9TEtah_kb9Gtv82jXiupZuFjp5wWNnLrZ4EBRoLvmT1zl2_fg4x2zfqug',
          ],
        ),
      ),
    ];
  }
}

import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/models/glucose_record.dart';
import 'package:health_care_app/models/glucose_record_validator.dart';

void main() {
  group('GlucoseRecord', () {
    test('toMap と fromMap で保存向けの変換ができる', () {
      final record = GlucoseRecord(
        recordedAt: DateTime(2026, 8, 30, 12, 30),
        bloodSugarMgDl: 120,
        mealTiming: MealTiming.beforeMeal,
        memo: '昼食前に測定',
        photoPaths: <String>['/tmp/photo_1.jpg', '/tmp/photo_2.jpg'],
      );

      final restored = GlucoseRecord.fromMap(record.toMap());

      expect(restored.recordedAt, record.recordedAt);
      expect(restored.bloodSugarMgDl, 120);
      expect(restored.mealTiming, MealTiming.beforeMeal);
      expect(restored.memo, '昼食前に測定');
      expect(restored.photoPaths, <String>[
        '/tmp/photo_1.jpg',
        '/tmp/photo_2.jpg',
      ]);
    });
  });

  group('GlucoseRecordValidator', () {
    test('仕様どおりの入力ならエラーなし', () {
      final result = GlucoseRecordValidator.validate(
        recordedAt: DateTime(2026, 8, 30, 12, 30),
        bloodSugarText: '145',
        mealTiming: MealTiming.afterMeal,
        memo: '外食',
        photoPaths: <String>['/tmp/photo_1.jpg'],
      );

      expect(result.isValid, isTrue);
      expect(result.errors, isEmpty);
    });

    test('仕様違反の入力ならエラーメッセージが返る', () {
      final result = GlucoseRecordValidator.validate(
        recordedAt: null,
        bloodSugarText: '145.5',
        mealTiming: null,
        memo: 'a' * 51,
        photoPaths: <String>[
          '/tmp/photo_1.jpg',
          '/tmp/photo_2.jpg',
          '/tmp/photo_3.jpg',
          '/tmp/photo_4.jpg',
        ],
      );

      expect(result.isValid, isFalse);
      expect(result.errors, contains('日時を入力してください。'));
      expect(result.errors, contains('血糖値は整数で入力してください。'));
      expect(result.errors, contains('測定タイミングを選択してください。'));
      expect(result.errors, contains('メモは50文字以内で入力してください。'));
      expect(result.errors, contains('写真は3枚まで追加できます。'));
    });
  });
}

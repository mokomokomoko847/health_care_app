import 'glucose_record.dart';

class GlucoseRecordValidator {
  static const int minBloodSugarMgDl = 0;
  static const int maxBloodSugarMgDl = 600;
  static const int maxMemoLength = 50;
  static const int maxPhotoCount = 3;

  // 入力画面から渡された値が仕様を満たしているかをまとめて確認する。
  static GlucoseRecordValidationResult validate({
    required DateTime? recordedAt,
    required String bloodSugarText,
    required MealTiming? mealTiming,
    required String memo,
    required List<String> photoPaths,
  }) {
    final errors = <String>[];

    if (recordedAt == null) {
      errors.add('日時を入力してください。');
    }

    final trimmedBloodSugarText = bloodSugarText.trim();

    if (trimmedBloodSugarText.isEmpty) {
      errors.add('血糖値を入力してください。');
    } else {
      final parsedValue = int.tryParse(trimmedBloodSugarText);

      if (parsedValue == null) {
        errors.add('血糖値は整数で入力してください。');
      } else if (parsedValue < minBloodSugarMgDl ||
          parsedValue > maxBloodSugarMgDl) {
        errors.add('血糖値は0〜600の範囲で入力してください。');
      }
    }

    if (mealTiming == null) {
      errors.add('測定タイミングを選択してください。');
    }

    if (memo.length > maxMemoLength) {
      errors.add('メモは50文字以内で入力してください。');
    }

    if (photoPaths.length > maxPhotoCount) {
      errors.add('写真は3枚まで追加できます。');
    }

    return GlucoseRecordValidationResult(errors: errors);
  }
}

class GlucoseRecordValidationResult {
  const GlucoseRecordValidationResult({required this.errors});

  final List<String> errors;

  bool get isValid => errors.isEmpty;
}

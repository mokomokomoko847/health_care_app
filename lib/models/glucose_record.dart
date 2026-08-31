enum MealTiming {
  beforeMeal('食前'),
  afterMeal('食後');

  const MealTiming(this.label);

  final String label;

  static MealTiming fromStorageValue(String value) {
    return MealTiming.values.firstWhere(
      (timing) => timing.name == value,
      orElse: () => MealTiming.beforeMeal,
    );
  }
}

class GlucoseRecord {
  GlucoseRecord({
    required this.recordedAt,
    required this.bloodSugarMgDl,
    required this.mealTiming,
    required this.memo,
    required this.photoPaths,
  });

  final DateTime recordedAt;
  final int bloodSugarMgDl;
  final MealTiming mealTiming;
  final String memo;
  final List<String> photoPaths;

  GlucoseRecord copyWith({
    DateTime? recordedAt,
    int? bloodSugarMgDl,
    MealTiming? mealTiming,
    String? memo,
    List<String>? photoPaths,
  }) {
    return GlucoseRecord(
      recordedAt: recordedAt ?? this.recordedAt,
      bloodSugarMgDl: bloodSugarMgDl ?? this.bloodSugarMgDl,
      mealTiming: mealTiming ?? this.mealTiming,
      memo: memo ?? this.memo,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'recordedAt': recordedAt.toIso8601String(),
      'bloodSugarMgDl': bloodSugarMgDl,
      'mealTiming': mealTiming.name,
      'memo': memo,
      'photoPaths': photoPaths,
    };
  }

  factory GlucoseRecord.fromMap(Map<String, dynamic> map) {
    final rawPhotoPaths = (map['photoPaths'] as List<dynamic>? ?? <dynamic>[])
        .map((path) => path.toString())
        .toList();

    return GlucoseRecord(
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      bloodSugarMgDl: map['bloodSugarMgDl'] as int,
      mealTiming: MealTiming.fromStorageValue(map['mealTiming'] as String),
      memo: (map['memo'] as String?) ?? '',
      photoPaths: rawPhotoPaths,
    );
  }
}

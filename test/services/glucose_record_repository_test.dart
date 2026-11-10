import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:health_care_app/models/glucose_record.dart';
import 'package:health_care_app/repositories/glucose_record_repository.dart';

void main() {
  test('ネイティブプラグイン未反映時は再ビルドを案内する', () {
    for (final error in [
      MissingPluginException(),
      PlatformException(code: 'channel-error'),
    ]) {
      expect(recordErrorMessage(error), contains('再ビルド'));
    }
    expect(
      recordErrorMessage(PlatformException(code: 'other')),
      '処理に失敗しました。もう一度お試しください。',
    );
  });

  late FakeFirebaseFirestore firestore;
  late FirestoreGlucoseRecordRepository repository;
  final day = DateTime(2026, 1, 15);

  GlucoseRecord record(DateTime at, {int value = 120}) => GlucoseRecord(
    recordedAt: at,
    bloodSugarMgDl: value,
    mealTiming: MealTiming.afterMeal,
    memo: '昼食後',
    photoPaths: [],
  );

  setUp(() {
    firestore = FakeFirebaseFirestore();
    repository = FirestoreGlucoseRecordRepository(firestore: firestore);
  });

  test('ユーザー別の保存先・Timestamp・サーバー日時を使用して読み戻す', () async {
    await repository.create('alice', 'first', record(day));
    final data =
        (await firestore.doc('users/alice/glucose_records/first').get())
            .data()!;
    expect(data.keys.toSet(), {
      'recordedAt',
      'bloodSugarMgDl',
      'mealTiming',
      'memo',
      'photoPaths',
      'createdAt',
      'updatedAt',
    });
    expect(data['recordedAt'], Timestamp.fromDate(day));
    expect(data['createdAt'], isA<Timestamp>());
    expect(data['updatedAt'], isA<Timestamp>());
    final result = await repository.loadRange(
      'alice',
      day,
      DateTime(2026, 1, 16),
    );
    expect(result.single.toMap(), record(day).toMap());
    expect(
      await repository.loadRange('bob', day, DateTime(2026, 1, 16)),
      isEmpty,
    );
  });

  test('開始を含み終了を含まない日付範囲で日時の昇順に取得する', () async {
    await repository.create(
      'alice',
      'late',
      record(DateTime(2026, 1, 15, 23, 59)),
    );
    await repository.create('alice', 'next', record(DateTime(2026, 1, 16)));
    await repository.create('alice', 'early', record(day));
    await repository.create(
      'alice',
      'previous',
      record(DateTime(2026, 1, 14, 23, 59)),
    );
    final result = await repository.loadRange(
      'alice',
      day,
      DateTime(2026, 1, 16),
    );
    expect(result.map((entry) => entry.recordedAt), [
      day,
      DateTime(2026, 1, 15, 23, 59),
    ]);
  });

  test('応答失敗後に同じIDで再試行しても重複・上書きをしない', () async {
    await repository.create('alice', 'same', record(day));
    await repository.create('alice', 'same', record(day));
    await expectLater(
      repository.create('alice', 'same', record(day, value: 130)),
      throwsA(
        isA<FirebaseException>().having(
          (e) => e.code,
          'code',
          'already-exists',
        ),
      ),
    );
    expect(
      (await firestore.collection('users/alice/glucose_records').get()).docs,
      hasLength(1),
    );
  });

  test('不正値・未来日時・ローカル写真パスはクラウドに保存しない', () async {
    for (final value in [-1, 601]) {
      await expectLater(
        repository.create('alice', 'bad', record(day, value: value)),
        throwsArgumentError,
      );
    }
    await expectLater(
      repository.create(
        'alice',
        'future',
        record(DateTime.now().add(const Duration(days: 1))),
      ),
      throwsArgumentError,
    );
    await expectLater(
      repository.create(
        'alice',
        'photo',
        record(day).copyWith(photoPaths: ['/tmp/photo.jpg']),
      ),
      throwsStateError,
    );
    expect(
      (await firestore.collection('users/alice/glucose_records').get()).docs,
      isEmpty,
    );
  });
}

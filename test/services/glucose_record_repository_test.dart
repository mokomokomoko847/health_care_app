import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:health_care_app/models/glucose_record.dart';
import 'package:health_care_app/repositories/glucose_record_repository.dart';
import 'dart:io';
import '../support/fake_photo_storage.dart';
import 'package:health_care_app/services/record_photo_storage_service.dart';

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
  late FakePhotoStorage photos;
  late Directory temporary;
  late String photoPath;
  final day = DateTime(2026, 1, 15);

  GlucoseRecord record(DateTime at, {int value = 120}) => GlucoseRecord(
    recordedAt: at,
    bloodSugarMgDl: value,
    mealTiming: MealTiming.afterMeal,
    memo: '昼食後',
    photoPaths: [],
  );

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    photos = FakePhotoStorage();
    repository = FirestoreGlucoseRecordRepository(
      firestore: firestore,
      photoStorage: photos,
    );
    temporary = await Directory.systemTemp.createTemp('record_photos');
    photoPath = (await File(
      '${temporary.path}/meal.png',
    ).writeAsBytes(testPhotoBytes)).path;
  });
  tearDown(() async => temporary.delete(recursive: true));

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

  test('不正値・未来日時はクラウドに保存しない', () async {
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
    expect(
      (await firestore.collection('users/alice/glucose_records').get()).docs,
      isEmpty,
    );
  });

  test('写真をStorageへ保存し参照を読み戻す。再試行時に再アップロードしない', () async {
    final entry = record(day).copyWith(photoPaths: [photoPath]);
    await repository.create('alice', 'meal', entry);
    final result = await repository.loadRange(
      'alice',
      day,
      day.add(const Duration(days: 1)),
    );
    final path = result.single.photoPaths.single;
    expect(path, startsWith('users/alice/glucose_records/meal/photos/'));
    expect(photos.files[path], testPhotoBytes);
    await repository.create('alice', 'meal', entry);
    expect(photos.uploadCalls, 1);
    await expectLater(
      repository.create('alice', 'meal', record(day)),
      throwsA(isA<FirebaseException>()),
    );
    expect(photos.files, hasLength(1));
  });

  test('途中のアップロード失敗では記録を作らず写真も回収し再試行できる', () async {
    photos.failAtUpload = 2;
    final entry = record(day).copyWith(photoPaths: [photoPath, photoPath]);
    await expectLater(
      repository.create('alice', 'meal', entry),
      throwsException,
    );
    expect(photos.files, isEmpty);
    expect(
      (await firestore.doc('users/alice/glucose_records/meal').get()).exists,
      isFalse,
    );
    photos.failAtUpload = null;
    await repository.create('alice', 'meal', entry);
    expect(
      (await firestore.doc('users/alice/glucose_records/meal').get()).exists,
      isTrue,
    );
  });

  test('後片付け失敗を通知し、次回保存では残った写真を回収する', () async {
    photos.failAtUpload = 1;
    photos.failDelete = true;
    await expectLater(
      repository.create(
        'alice',
        'meal',
        record(day).copyWith(photoPaths: [photoPath]),
      ),
      throwsA(isA<PhotoStorageException>()),
    );
    expect(photos.files, isNotEmpty);
    photos.failDelete = false;
    await repository.create('alice', 'meal', record(day));
    expect(photos.files, isEmpty);
  });

  test('写真アップロード後に記録の確定が失敗した場合も写真を回収する', () async {
    photos.afterUpload = () async {
      await firestore.doc('users/alice/glucose_records/meal').set({
        'recordedAt': Timestamp.fromDate(day),
        'bloodSugarMgDl': 130,
        'mealTiming': MealTiming.afterMeal.name,
        'memo': '別の記録',
        'photoPaths': <String>[],
      });
    };
    await expectLater(
      repository.create(
        'alice',
        'meal',
        record(day).copyWith(photoPaths: [photoPath]),
      ),
      throwsA(isA<FirebaseException>()),
    );
    expect(photos.files, isEmpty);
    expect(
      (await firestore.doc('users/alice/glucose_records/meal').get())
          .data()!['bloodSugarMgDl'],
      130,
    );
  });

  test('保存成功後に応答が途切れても保存済み写真は削除しない', () async {
    photos.afterUpload = () async {
      await firestore.doc('users/alice/glucose_records/meal').set({
        'recordedAt': Timestamp.fromDate(day),
        'bloodSugarMgDl': 120,
        'mealTiming': MealTiming.afterMeal.name,
        'memo': '昼食後',
        'photoPaths': photos.files.keys.toList(),
      });
      throw FirebaseException(plugin: 'cloud_firestore', code: 'unavailable');
    };
    await repository.create(
      'alice',
      'meal',
      record(day).copyWith(photoPaths: [photoPath]),
    );
    expect(photos.files, hasLength(1));
  });

  test('画像の型・空ファイル・10MB超過・4枚を拒否する', () async {
    final invalid = await File(
      '${temporary.path}/invalid.txt',
    ).writeAsString('invalid');
    final empty = await File('${temporary.path}/empty.png').writeAsBytes([]);
    final large = await File(
      '${temporary.path}/large.png',
    ).open(mode: FileMode.write);
    await large.truncate(RecordPhotoStorageService.maxPhotoBytes + 1);
    await large.close();
    for (final path in [
      invalid.path,
      empty.path,
      '${temporary.path}/large.png',
    ]) {
      await expectLater(
        repository.create(
          'alice',
          'bad',
          record(day).copyWith(photoPaths: [path]),
        ),
        throwsA(isA<PhotoStorageException>()),
      );
    }
    await expectLater(
      repository.create(
        'alice',
        'bad',
        record(day).copyWith(photoPaths: List.filled(4, photoPath)),
      ),
      throwsArgumentError,
    );
    expect(photos.uploadCalls, 0);
  });
}

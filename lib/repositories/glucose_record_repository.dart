import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

import '../models/glucose_record.dart';
import '../models/glucose_record_validator.dart';
import '../services/record_photo_storage_service.dart';

abstract class GlucoseRecordRepository {
  String newRecordId();
  Future<void> create(String userId, String recordId, GlucoseRecord record);
  Future<List<GlucoseRecord>> loadRange(
    String userId,
    DateTime start,
    DateTime end,
  );
}

class FirestoreGlucoseRecordRepository implements GlucoseRecordRepository {
  FirestoreGlucoseRecordRepository({
    FirebaseFirestore? firestore,
    RecordPhotoStorageService? photoStorage,
  }) : _providedFirestore = firestore,
       _photoStorage = photoStorage ?? RecordPhotoStorageService();

  final FirebaseFirestore? _providedFirestore;
  final RecordPhotoStorageService _photoStorage;
  final Map<String, Set<String>> _pendingPhotos = {};
  FirebaseFirestore get _firestore =>
      _providedFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _records(String userId) {
    if (userId.isEmpty) throw StateError('認証が必要です。');
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('glucose_records');
  }

  @override
  String newRecordId() => _firestore.collection('users').doc().id;

  @override
  Future<void> create(
    String userId,
    String recordId,
    GlucoseRecord record,
  ) async {
    final validation = GlucoseRecordValidator.validate(
      recordedAt: record.recordedAt,
      bloodSugarText: record.bloodSugarMgDl.toString(),
      mealTiming: record.mealTiming,
      memo: record.memo,
      photoPaths: record.photoPaths,
    );
    if (!validation.isValid) throw ArgumentError(validation.errors.join('\n'));
    if (record.recordedAt.isAfter(DateTime.now())) {
      throw ArgumentError('現在より未来の日時は保存できません。');
    }
    final reference = _records(userId).doc(recordId);
    final photos = await _photoStorage.prepare(
      userId,
      recordId,
      record.photoPaths,
    );
    final storedRecord = record.copyWith(
      photoPaths: photos.map((photo) => photo.path).toList(),
    );
    bool matches(Map<String, dynamic> data) =>
        (data['recordedAt'] as Timestamp).toDate().isAtSameMomentAs(
          record.recordedAt,
        ) &&
        data['bloodSugarMgDl'] == record.bloodSugarMgDl &&
        data['mealTiming'] == record.mealTiming.name &&
        data['memo'] == record.memo &&
        listEquals(
          List<String>.from(data['photoPaths'] as List),
          storedRecord.photoPaths,
        );

    // オンラインで既存結果を確かめてから写真を準備する。
    final existing = await reference.get(
      const GetOptions(source: Source.server),
    );
    // 前回の後片付け中に通信が切れた場合も、再試行時に回収する。
    final pendingKey = reference.path;
    Future<void> cleanPending(Map<String, dynamic>? data) async {
      final referenced = data?['photoPaths'] as List? ?? [];
      final pending = _pendingPhotos[pendingKey];
      if (pending == null) return;
      for (final path in pending.toList()) {
        if (!referenced.contains(path)) await _photoStorage.delete(path);
        pending.remove(path);
      }
      _pendingPhotos.remove(pendingKey);
    }

    await cleanPending(existing.data());
    if (existing.exists) {
      if (matches(existing.data()!)) return;
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'already-exists',
      );
    }
    final attemptedPhotos = _pendingPhotos.putIfAbsent(
      pendingKey,
      () => <String>{},
    );
    try {
      for (final photo in photos) {
        attemptedPhotos.add(photo.path);
        await _photoStorage.upload(photo);
      }
      // トランザクションはオフライン時に失敗し、保留書き込みを残さない。
      // 入力画面が同じIDで再試行することで、応答が途切れた場合も重複登録を防ぐ。
      await _firestore.runTransaction((transaction) async {
        final existing = await transaction.get(reference);
        if (existing.exists) {
          final data = existing.data()!;
          if (matches(data)) {
            return;
          }
          throw FirebaseException(
            plugin: 'cloud_firestore',
            code: 'already-exists',
          );
        }
        transaction.set(reference, {
          'recordedAt': Timestamp.fromDate(record.recordedAt),
          'bloodSugarMgDl': record.bloodSugarMgDl,
          'mealTiming': record.mealTiming.name,
          'memo': record.memo,
          'photoPaths': storedRecord.photoPaths,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
      _pendingPhotos.remove(pendingKey);
    } catch (error, stackTrace) {
      if (attemptedPhotos.isNotEmpty) {
        // 応答だけ途切れた場合、保存済みの写真を削除しない。
        // 確認にも失敗した場合は破棄せず、同じID・写真で再試行する。
        final result = await reference.get(
          const GetOptions(source: Source.server),
        );
        if (result.exists && matches(result.data()!)) {
          _pendingPhotos.remove(pendingKey);
          return;
        }
        try {
          await cleanPending(result.data());
        } catch (_) {
          throw const PhotoStorageException(
            '保存できず、写真の後片付けも完了していません。接続を確認して、同じ入力画面でもう一度保存してください。',
          );
        }
      }
      Error.throwWithStackTrace(error, stackTrace);
    }
  }

  @override
  Future<List<GlucoseRecord>> loadRange(
    String userId,
    DateTime start,
    DateTime end,
  ) async {
    // キャッシュだけの結果を最新の取得成功として表示しない。
    final snapshot = await _records(userId)
        .where('recordedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('recordedAt', isLessThan: Timestamp.fromDate(end))
        .orderBy('recordedAt')
        .get(const GetOptions(source: Source.server));
    return snapshot.docs.map((document) {
      final data = document.data();
      return GlucoseRecord.fromMap({
        ...data,
        'recordedAt': (data['recordedAt'] as Timestamp)
            .toDate()
            .toLocal()
            .toIso8601String(),
      });
    }).toList();
  }
}

String recordErrorMessage(Object error) {
  if (error is PhotoStorageException) return error.message;
  // ネイティブプラグインの追加はホットリスタートだけでは反映されない。
  if (error is MissingPluginException ||
      (error is PlatformException && error.code == 'channel-error')) {
    return '保存機能を読み込めませんでした。アプリを完全に終了して起動し直してください。開発中の場合はアプリを停止し、再ビルドしてください。';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => '通信できません。接続を確認して、もう一度お試しください。',
      'retry-limit-exceeded' => '通信できません。接続を確認して、もう一度お試しください。',
      'unauthorized' => '写真にアクセスできません。ログイン状態とメール確認、Storageの設定を確認してください。',
      'bucket-not-found' ||
      'no-default-bucket' => '写真の保存先が設定されていません。Firebase Storageの設定を確認してください。',
      'permission-denied' ||
      'unauthenticated' => '記録にアクセスできません。ログイン状態とメール確認、Firestoreの設定を確認してください。',
      'already-exists' => '保存結果を確認できませんでした。カレンダーで記録を確認してください。',
      _ => '処理に失敗しました。もう一度お試しください。',
    };
  }
  return '処理に失敗しました。もう一度お試しください。';
}

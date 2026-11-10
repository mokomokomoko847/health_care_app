import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/glucose_record.dart';
import '../models/glucose_record_validator.dart';

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
  FirestoreGlucoseRecordRepository({FirebaseFirestore? firestore})
    : _providedFirestore = firestore;

  final FirebaseFirestore? _providedFirestore;
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
    // 写真を端末内パスのままクラウドへ保存しない。
    if (record.photoPaths.isNotEmpty) {
      throw StateError('写真のクラウド保存はまだ設定されていません。');
    }
    final reference = _records(userId).doc(recordId);
    // トランザクションはオフライン時に失敗し、保留書き込みを残さない。
    // 入力画面が同じIDで再試行することで、応答が途切れた場合も重複登録を防ぐ。
    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) {
        final data = existing.data()!;
        if ((data['recordedAt'] as Timestamp).toDate().isAtSameMomentAs(
              record.recordedAt,
            ) &&
            data['bloodSugarMgDl'] == record.bloodSugarMgDl &&
            data['mealTiming'] == record.mealTiming.name &&
            data['memo'] == record.memo) {
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
        'photoPaths': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
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
  // ネイティブプラグインの追加はホットリスタートだけでは反映されない。
  if (error is MissingPluginException ||
      (error is PlatformException && error.code == 'channel-error')) {
    return '保存機能を読み込めませんでした。アプリを完全に終了して起動し直してください。開発中の場合はアプリを停止し、再ビルドしてください。';
  }
  if (error is FirebaseException) {
    return switch (error.code) {
      'unavailable' || 'deadline-exceeded' => '通信できません。接続を確認して、もう一度お試しください。',
      'permission-denied' ||
      'unauthenticated' => '記録にアクセスできません。ログイン状態とメール確認、Firestoreの設定を確認してください。',
      'already-exists' => '保存結果を確認できませんでした。カレンダーで記録を確認してください。',
      _ => '処理に失敗しました。もう一度お試しください。',
    };
  }
  return '処理に失敗しました。もう一度お試しください。';
}

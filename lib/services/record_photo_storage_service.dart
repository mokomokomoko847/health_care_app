import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:mime/mime.dart';

class PreparedRecordPhoto {
  const PreparedRecordPhoto(this.path, this.bytes, this.contentType);

  final String path;
  final Uint8List bytes;
  final String contentType;
}

class PhotoStorageException implements Exception {
  const PhotoStorageException(this.message);
  final String message;
}

class RecordPhotoStorageService {
  RecordPhotoStorageService({FirebaseStorage? storage})
    : _providedStorage = storage;

  static const maxPhotoBytes = 10 * 1024 * 1024;
  final FirebaseStorage? _providedStorage;
  FirebaseStorage get _storage => _providedStorage ?? FirebaseStorage.instance;

  Future<List<PreparedRecordPhoto>> prepare(
    String userId,
    String recordId,
    List<String> localPaths,
  ) async {
    final photos = <PreparedRecordPhoto>[];
    for (final localPath in localPaths) {
      final bytes = await _readLocalPhoto(localPath);
      final contentType = await _imageContentType(localPath, bytes);
      // 内容から名前を決め、保存の再試行でも同じ写真を重複作成しない。
      final name = sha256.convert(bytes).toString();
      photos.add(
        PreparedRecordPhoto(
          'users/$userId/glucose_records/$recordId/photos/$name',
          bytes,
          contentType,
        ),
      );
    }
    return photos;
  }

  Future<Uint8List> _readLocalPhoto(String path) async {
    final file = File(path);
    try {
      if (await file.length() <= maxPhotoBytes) {
        final bytes = await file.readAsBytes();
        if (bytes.length <= maxPhotoBytes) return bytes;
      }
    } on FileSystemException {
      throw const PhotoStorageException('写真を読み込めませんでした。写真を選び直してください。');
    }
    throw const PhotoStorageException('写真は1枚10MB以下にしてください。');
  }

  Future<String> _imageContentType(String path, Uint8List bytes) async {
    final headerType = lookupMimeType('', headerBytes: bytes);
    if (headerType?.startsWith('image/') == true) return headerType!;
    // ヘッダーの定義がない形式は、Flutterで表示できることを確かめる。
    final extensionType = lookupMimeType(path);
    if (headerType == null &&
        bytes.isNotEmpty &&
        extensionType?.startsWith('image/') == true) {
      try {
        final codec = await ui.instantiateImageCodec(bytes, targetWidth: 1);
        codec.dispose();
        return extensionType!;
      } on Exception {
        // 拡張子と実データが一致しないファイルは登録しない。
      }
    }
    throw const PhotoStorageException('画像ファイルを選択してください（1枚10MB以下）。');
  }

  Future<void> upload(PreparedRecordPhoto photo) async {
    final reference = _storage.ref(photo.path);
    try {
      await reference.getMetadata();
      return; // 前回のアップロードが成功済みなら再利用する。
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
    await reference.putData(
      photo.bytes,
      SettableMetadata(contentType: photo.contentType),
    );
  }

  Future<void> delete(String path) async {
    try {
      await _storage.ref(path).delete();
    } on FirebaseException catch (error) {
      if (error.code != 'object-not-found') rethrow;
    }
  }

  // 公開URLを発行せず、取得時にもFirebaseの認証とルールを適用する。
  Future<Uint8List?> read(String path) async =>
      _storage.ref(path).getData(maxPhotoBytes);
}

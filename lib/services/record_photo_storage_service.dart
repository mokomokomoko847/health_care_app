import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:crypto/crypto.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:image/image.dart' as image;

class PreparedRecordPhoto {
  const PreparedRecordPhoto(this.path, this.bytes, this.contentType);

  final String path;
  final Uint8List bytes;
  final String contentType;
}

class PhotoStorageException implements Exception {
  const PhotoStorageException(
    this.message, {
    this.retryWithNewRecordId = false,
  });
  final String message;
  final bool retryWithNewRecordId;
}

class RecordPhotoStorageService {
  RecordPhotoStorageService({FirebaseStorage? storage})
    : _providedStorage = storage;

  static const maxPhotoBytes = 10 * 1024 * 1024;
  static const maxCompressedPhotoBytes = 256 * 1024;
  static const _maxPhotoSide = 1280;
  final FirebaseStorage? _providedStorage;
  FirebaseStorage get _storage => _providedStorage ?? FirebaseStorage.instance;

  Future<List<PreparedRecordPhoto>> prepare(
    String userId,
    String recordId,
    List<String> localPaths,
  ) async {
    final photos = <PreparedRecordPhoto>[];
    for (final localPath in localPaths) {
      final bytes = await _compressPhoto(await _readLocalPhoto(localPath));
      // 内容から名前を決め、保存の再試行でも同じ写真を重複作成しない。
      final name = sha256.convert(bytes).toString();
      photos.add(
        PreparedRecordPhoto(
          'users/$userId/glucose_records/$recordId/compressed/$name',
          bytes,
          'image/jpeg',
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

  Future<Uint8List> _compressPhoto(Uint8List bytes) async {
    final (pixels, width, height) = await _decodePhoto(bytes);
    final compressed = await compute(_encodeJpeg, (pixels, width, height));
    if (compressed != null) return compressed;
    throw const PhotoStorageException('写真を256 KiB以下に圧縮できませんでした。別の写真を選んでください。');
  }

  Future<(ByteData, int, int)> _decodePhoto(Uint8List bytes) async {
    ui.ImmutableBuffer? buffer;
    ui.ImageDescriptor? descriptor;
    ui.Codec? codec;
    ui.Image? decoded;
    try {
      buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
      descriptor = await ui.ImageDescriptor.encoded(buffer);
      final width = descriptor.width;
      final height = descriptor.height;
      final scale = math.min(1.0, _maxPhotoSide / math.max(width, height));
      codec = await descriptor.instantiateCodec(
        targetWidth: math.max(1, (width * scale).round()),
        targetHeight: math.max(1, (height * scale).round()),
      );
      decoded = (await codec.getNextFrame()).image;
      final pixels = await decoded.toByteData(
        format: ui.ImageByteFormat.rawStraightRgba,
      );
      if (pixels != null) return (pixels, decoded.width, decoded.height);
    } on Exception {
      // デコードできないファイルはアップロードしない。
    } finally {
      decoded?.dispose();
      codec?.dispose();
      descriptor?.dispose();
      buffer?.dispose();
    }
    throw const PhotoStorageException('画像ファイルを選択してください（1枚10MB以下）。');
  }

  // JPEGのエンコードは別のisolateで行い、圧縮後の容量を超える場合だけ縮小する。
  static Uint8List? _encodeJpeg((ByteData, int, int) input) {
    final (pixels, width, height) = input;
    var photo = image.Image.fromBytes(
      width: width,
      height: height,
      bytes: pixels.buffer,
      bytesOffset: pixels.offsetInBytes,
      numChannels: 4,
    );
    while (true) {
      for (final quality in [76, 64, 52]) {
        final jpeg = image.encodeJpg(
          photo,
          quality: quality,
          chroma: image.JpegChroma.yuv420,
        );
        if (jpeg.length <= maxCompressedPhotoBytes) return jpeg;
      }
      final longestSide = math.max(photo.width, photo.height);
      if (longestSide <= 480) return null;
      final scale = math.max(480, (longestSide * .75).round()) / longestSide;
      photo = image.copyResize(
        photo,
        width: math.max(1, (photo.width * scale).round()),
        height: math.max(1, (photo.height * scale).round()),
        interpolation: image.Interpolation.average,
      );
    }
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
  Future<Uint8List?> read(String path) async => _storage
      .ref(path)
      .getData(
        path.split('/').elementAtOrNull(4) == 'compressed'
            ? maxCompressedPhotoBytes
            : maxPhotoBytes,
      );
}

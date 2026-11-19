import 'dart:convert';
import 'dart:typed_data';

import 'package:health_care_app/services/record_photo_storage_service.dart';

final testPhotoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR4nGP4P4/xPwAG3AKeybdB8wAAAABJRU5ErkJggg==',
);

class FakePhotoStorage extends RecordPhotoStorageService {
  final Map<String, Uint8List> files = {};
  int uploadCalls = 0;
  int readCalls = 0;
  int? failAtUpload;
  Object? uploadError;
  bool failDelete = false;
  Future<void> Function()? afterUpload;

  @override
  Future<void> upload(PreparedRecordPhoto photo) async {
    uploadCalls++;
    files[photo.path] = photo.bytes;
    if (uploadCalls == failAtUpload) {
      throw uploadError ?? Exception('upload failed');
    }
    await afterUpload?.call();
  }

  @override
  Future<void> delete(String path) async {
    if (failDelete) throw Exception('delete failed');
    files.remove(path);
  }

  @override
  Future<Uint8List?> read(String path) async {
    readCalls++;
    return files[path];
  }
}

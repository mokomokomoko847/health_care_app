import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../services/record_photo_storage_service.dart';

class RecordPhoto extends StatefulWidget {
  const RecordPhoto({super.key, required this.path, this.photoStorage});

  final String path;
  final RecordPhotoStorageService? photoStorage;

  @override
  State<RecordPhoto> createState() => _RecordPhotoState();
}

class _RecordPhotoState extends State<RecordPhoto> {
  Future<Uint8List?>? _bytes;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant RecordPhoto oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.photoStorage != widget.photoStorage) {
      _load();
    }
  }

  void _load() {
    // サンプル画面のHTTP画像も引き続き表示する。
    _bytes = widget.path.startsWith('users/')
        ? (widget.photoStorage ?? RecordPhotoStorageService()).read(widget.path)
        : null;
  }

  Widget _error() => ColoredBox(
    color: const Color(0xFFDCE2F7),
    child: Center(
      child: IconButton(
        tooltip: '写真を再読み込み',
        onPressed: () => setState(_load),
        icon: const Icon(Icons.broken_image_outlined),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    if (_bytes == null) {
      return Image.network(
        widget.path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _error(),
      );
    }
    return FutureBuilder<Uint8List?>(
      future: _bytes,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.hasError) return _error();
        return Image.memory(
          snapshot.data!,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _error(),
        );
      },
    );
  }
}

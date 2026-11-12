import 'dart:async';
import 'dart:io';

import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/pages/record_input_page.dart';
import 'package:health_care_app/repositories/glucose_record_repository.dart';
import 'package:health_care_app/services/photo_picker_service.dart';
import 'package:health_care_app/services/record_photo_storage_service.dart';
import 'package:health_care_app/widgets/record_photo.dart';

import 'support/fake_photo_storage.dart';

class FakePhotoPicker extends PhotoPickerService {
  String? nextPath;
  Object? error;
  Completer<String?>? pending;
  int cameraCalls = 0;
  int galleryCalls = 0;

  Future<String?> pick() async {
    if (error != null) throw error!;
    return pending != null ? pending!.future : nextPath;
  }

  @override
  Future<String?> pickFromCamera() {
    cameraCalls++;
    return pick();
  }

  @override
  Future<String?> pickFromGallery() {
    galleryCalls++;
    return pick();
  }
}

class WidgetPhotoStorage extends FakePhotoStorage {
  @override
  Future<List<PreparedRecordPhoto>> prepare(
    String userId,
    String recordId,
    List<String> localPaths,
  ) async => [
    for (var index = 0; index < localPaths.length; index++)
      PreparedRecordPhoto(
        'users/$userId/glucose_records/$recordId/photos/$index',
        testPhotoBytes,
        'image/png',
      ),
  ];
}

void main() {
  late Directory temporary;
  late FakePhotoPicker picker;
  late FakePhotoStorage storage;
  late FirestoreGlucoseRecordRepository repository;
  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('record_photos_widget');
    picker = FakePhotoPicker()
      ..nextPath = (await File(
        '${temporary.path}/meal.png',
      ).writeAsBytes(testPhotoBytes)).path;
    storage = WidgetPhotoStorage();
    repository = FirestoreGlucoseRecordRepository(
      firestore: FakeFirebaseFirestore(),
      photoStorage: storage,
    );
  });
  tearDown(() async => temporary.delete(recursive: true));

  Future<void> open(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => RecordInputPage(
                    photoPickerService: picker,
                    repository: repository,
                    userId: 'alice',
                  ),
                ),
              ),
              child: const Text('開く'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開く'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, '123');
    await tester.enterText(find.byType(TextField).last, 'メモを保持');
    await tester.scrollUntilVisible(
      find.text('記録を保存'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('カメラ・画像選択で最大3枚まで追加、削除、写真付きで保存できる', (tester) async {
    await open(tester);
    await tester.tap(find.text('カメラ撮影'));
    await tester.pumpAndSettle();
    expect(find.byTooltip('写真を削除'), findsOneWidget);
    await tester.tap(find.text('画像選択'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('画像選択'));
    await tester.pumpAndSettle();
    expect(find.text('3/3枚'), findsOneWidget);
    await tester.tap(find.text('画像選択'));
    await tester.pumpAndSettle();
    expect(picker.cameraCalls, 1);
    expect(picker.galleryCalls, 2);
    await tester.tap(find.byTooltip('写真を削除').first);
    await tester.pumpAndSettle();
    expect(find.text('2/3枚'), findsOneWidget);
    await tester.tap(find.text('記録を保存'));
    await tester.pumpAndSettle();
    expect(find.byType(RecordInputPage), findsNothing);
    final now = DateTime.now();
    final records = await repository.loadRange(
      'alice',
      DateTime(now.year, now.month, now.day),
      now.add(const Duration(days: 1)),
    );
    expect(records.single.photoPaths, hasLength(2));
    expect(storage.files, isNotEmpty);
  });

  testWidgets('選択キャンセル・権限拒否で入力を保持し、取り込み中の重複操作を防ぐ', (tester) async {
    await open(tester);
    picker.nextPath = null;
    await tester.tap(find.text('画像選択'));
    await tester.pumpAndSettle();
    expect(find.text('0/3枚'), findsOneWidget);
    picker.error = PlatformException(code: 'camera_access_denied');
    await tester.tap(find.text('カメラ撮影'));
    await tester.pumpAndSettle();
    expect(find.textContaining('カメラを利用できません'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField).first).controller!.text,
      'メモを保持',
    );
    picker.error = null;
    picker.pending = Completer<String?>();
    await tester.tap(find.text('画像選択'));
    await tester.pump();
    await tester.tap(find.text('画像選択'), warnIfMissed: false);
    await tester.tap(find.text('記録を保存'), warnIfMissed: false);
    await tester.pump();
    expect(find.byType(RecordInputPage), findsOneWidget);
    expect(picker.galleryCalls, 2);
    picker.pending!.complete(null);
    await tester.pumpAndSettle();
  });

  testWidgets('保存済みの写真を認証付き取得で表示し、失敗時に再読み込みできる', (tester) async {
    const path = 'users/alice/glucose_records/meal/photos/test';
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox.square(
          dimension: 96,
          child: RecordPhoto(path: path, photoStorage: storage),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byTooltip('写真を再読み込み'), findsOneWidget);
    storage.files[path] = testPhotoBytes;
    await tester.tap(find.byTooltip('写真を再読み込み'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsOneWidget);
    expect(storage.readCalls, 2);
  });
}

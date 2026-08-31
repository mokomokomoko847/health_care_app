import 'package:flutter_test/flutter_test.dart';
import 'package:health_care_app/services/app_database.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late DatabaseFactory databaseFactory;
  late String databasePath;
  late AppDatabase appDatabase;

  setUp(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    databasePath = path.join(inMemoryDatabasePath, AppDatabase.databaseName);
    appDatabase = AppDatabase(
      databaseFactory: databaseFactory,
      databasePath: databasePath,
    );
  });

  test('SQLiteの土台として必要な2テーブルを作成できる', () async {
    final database = await appDatabase.open();

    addTearDown(database.close);

    final tables = await database.query(
      'sqlite_master',
      columns: <String>['name'],
      where: 'type = ?',
      whereArgs: <Object?>['table'],
    );

    final tableNames = tables
        .map((table) => table['name'] as String)
        .toSet();

    expect(tableNames, contains(AppDatabase.glucoseRecordsTable));
    expect(tableNames, contains(AppDatabase.glucoseRecordPhotosTable));
  });

  test('glucose_records テーブルが設計どおりのカラムを持つ', () async {
    final database = await appDatabase.open();

    addTearDown(database.close);

    final columns = await database.rawQuery(
      'PRAGMA table_info(${AppDatabase.glucoseRecordsTable});',
    );

    expect(columns.map((column) => column['name']), <String>[
      'id',
      'recorded_at',
      'blood_sugar_mg_dl',
      'meal_timing',
      'memo',
      'created_at',
      'updated_at',
    ]);
  });

  test('glucose_record_photos テーブルが設計どおりのカラムを持つ', () async {
    final database = await appDatabase.open();

    addTearDown(database.close);

    final columns = await database.rawQuery(
      'PRAGMA table_info(${AppDatabase.glucoseRecordPhotosTable});',
    );

    expect(columns.map((column) => column['name']), <String>[
      'id',
      'record_id',
      'photo_path',
      'sort_order',
      'created_at',
    ]);
  });
}

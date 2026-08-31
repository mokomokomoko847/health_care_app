import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

class AppDatabase {
  AppDatabase({
    sqflite.DatabaseFactory? databaseFactory,
    String? databasePath,
  })  : _databaseFactory = databaseFactory ?? sqflite.databaseFactory,
        _databasePath = databasePath;

  static const String databaseName = 'health_care_app.db';
  static const int databaseVersion = 1;

  static const String glucoseRecordsTable = 'glucose_records';
  static const String glucoseRecordPhotosTable = 'glucose_record_photos';

  final sqflite.DatabaseFactory _databaseFactory;
  final String? _databasePath;

  Future<sqflite.Database> open() async {
    final resolvedDatabasePath = _databasePath ?? await _defaultDatabasePath();

    return _databaseFactory.openDatabase(
      resolvedDatabasePath,
      options: sqflite.OpenDatabaseOptions(
        version: databaseVersion,
        onConfigure: (database) async {
          // 外部キー制約を有効にして、写真データが必ず記録に紐づくようにする。
          await database.execute('PRAGMA foreign_keys = ON;');
        },
        onCreate: (database, version) async {
          await database.execute(_createGlucoseRecordsTableSql);
          await database.execute(_createGlucoseRecordPhotosTableSql);
        },
      ),
    );
  }

  Future<String> _defaultDatabasePath() async {
    final databasesDirectory = await sqflite.getDatabasesPath();

    return path.join(databasesDirectory, databaseName);
  }

  static const String _createGlucoseRecordsTableSql = '''
CREATE TABLE glucose_records (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  recorded_at TEXT NOT NULL,
  blood_sugar_mg_dl INTEGER NOT NULL,
  meal_timing TEXT NOT NULL,
  memo TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);
''';

  static const String _createGlucoseRecordPhotosTableSql = '''
CREATE TABLE glucose_record_photos (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  record_id INTEGER NOT NULL,
  photo_path TEXT NOT NULL,
  sort_order INTEGER NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY (record_id) REFERENCES glucose_records (id) ON DELETE CASCADE
);
''';
}

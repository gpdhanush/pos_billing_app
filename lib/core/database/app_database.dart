import 'package:path/path.dart' as p;
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/migrations/migration_v1.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase(this.db);

  final Database db;

  static Future<String> defaultFilePath() async {
    return p.join(await getDatabasesPath(), DbConstants.fileName);
  }

  static Future<AppDatabase> open({String? path, bool inMemory = false}) async {
    final Database database;
    if (inMemory) {
      database = await openDatabase(
        inMemoryDatabasePath,
        version: DbConstants.schemaVersion,
        onConfigure: _onConfigure,
        onCreate: (db, version) => MigrationV1.apply(db),
        onUpgrade: _onUpgrade,
      );
    } else {
      final dbPath = path ?? await defaultFilePath();
      database = await openDatabase(
        dbPath,
        version: DbConstants.schemaVersion,
        onConfigure: _onConfigure,
        onCreate: (db, version) => MigrationV1.apply(db),
        onUpgrade: _onUpgrade,
      );
    }
    return AppDatabase(database);
  }

  /// Closes the current DB, deletes the file, and opens a fresh empty schema.
  static Future<AppDatabase> wipeAndReopen(AppDatabase current) async {
    final path = current.db.path;
    await current.close();
    await deleteDatabase(path);
    return AppDatabase.open(path: path);
  }

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Versioned, additive migrations only. Never drop user data.
    // Play Store updates: bump DbConstants.schemaVersion, add MigrationVn,
    // and call it here when oldVersion < n.
    if (oldVersion < 1) {
      await MigrationV1.apply(db);
    }
    // Example for a future release:
    // if (oldVersion < 2) {
    //   await MigrationV2.apply(db);
    // }
  }

  Future<T> transaction<T>(Future<T> Function(Transaction txn) action) {
    return db.transaction(action);
  }

  Future<void> close() => db.close();
}

extension Executor on DatabaseExecutor {
  Future<List<Map<String, Object?>>> select(
    String sql, [
    List<Object?> arguments = const [],
  ]) =>
      rawQuery(sql, arguments);
}

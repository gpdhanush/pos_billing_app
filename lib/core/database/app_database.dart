import 'package:path/path.dart' as p;
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/migrations/migration_v1.dart';
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase(this.db);

  final Database db;

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
      final dbPath = path ?? p.join(await getDatabasesPath(), DbConstants.fileName);
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

  static Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  static Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Versioned, additive migrations only. Never drop user data.
    if (oldVersion < 1) {
      await MigrationV1.apply(db);
    }
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

import 'package:pos_billing/core/database/app_database.dart';
import 'package:sqflite/sqflite.dart';

class SettingsRepository {
  SettingsRepository(this._db);

  final AppDatabase _db;

  DatabaseExecutor get _ex => _db.db;

  Future<String?> get(String key) async {
    final rows = await _ex.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  Future<void> set(String key, String value) async {
    await _ex.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<bool> getBool(String key, {bool fallback = false}) async {
    final value = await get(key);
    if (value == null) return fallback;
    return value == '1' || value == 'true';
  }

  Future<void> setBool(String key, bool value) => set(key, value ? '1' : '0');

  Future<Map<String, String>> getAll() async {
    final rows = await _ex.query('settings');
    return {
      for (final row in rows) row['key'] as String: row['value'] as String,
    };
  }
}

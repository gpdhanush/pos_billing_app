import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/store_profile.dart';
import 'package:sqflite/sqflite.dart';

class StoreRepository {
  StoreRepository(this._db);

  final AppDatabase _db;

  Future<StoreProfile?> loadStore() async {
    final rows = await _db.db.query('stores', orderBy: 'id ASC', limit: 1);
    if (rows.isEmpty) return null;
    return StoreProfile.fromMap(rows.first);
  }

  Future<StoreProfile> createStore(StoreProfile draft) async {
    final id = await _db.db.insert('stores', draft.toMap());
    await _db.db.insert('users', {
      'name': 'Owner',
      'created_at': nowMillis(),
    });
    await _db.db.insert('categories', {
      'store_id': id,
      'name': 'General',
      'is_active': 1,
      'created_at': nowMillis(),
      'updated_at': nowMillis(),
    });
    return (await loadStore())!;
  }

  Future<StoreProfile> updateStore(StoreProfile store) async {
    await _db.db.update(
      'stores',
      store.copyWith(updatedAt: nowMillis()).toMap(),
      where: 'id = ?',
      whereArgs: [store.id],
    );
    return (await loadStore())!;
  }

  Future<void> updateLogo(int storeId, String? path) async {
    await _db.db.update(
      'stores',
      {'logo_path': path, 'updated_at': nowMillis()},
      where: 'id = ?',
      whereArgs: [storeId],
    );
  }

  Future<StoreProfile> completeSetup(StoreProfile store) async {
    return updateStore(store.copyWith(isSetupCompleted: true));
  }

  Future<int> peekNextInvoiceNumber(int storeId) async {
    final rows = await _db.db.query(
      'stores',
      columns: ['next_invoice_number'],
      where: 'id = ?',
      whereArgs: [storeId],
    );
    return (rows.first['next_invoice_number'] as int?) ?? 1;
  }

  Future<(String prefix, int number)> consumeInvoiceNumber(Transaction txn, int storeId) async {
    final rows = await txn.query(
      'stores',
      columns: ['invoice_prefix', 'next_invoice_number'],
      where: 'id = ?',
      whereArgs: [storeId],
    );
    final prefix = (rows.first['invoice_prefix'] as String?) ?? 'INV';
    final number = (rows.first['next_invoice_number'] as int?) ?? 1;
    await txn.update(
      'stores',
      {
        'next_invoice_number': number + 1,
        'updated_at': nowMillis(),
      },
      where: 'id = ?',
      whereArgs: [storeId],
    );
    return (prefix, number);
  }

  Future<void> audit({
    required String action,
    String? entityType,
    int? entityId,
    String? metadata,
    int? userId,
  }) async {
    await _db.db.insert('audit_logs', {
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'created_at': nowMillis(),
      'user_id': userId,
    });
  }

  Future<int?> defaultUserId() async {
    final rows = await _db.db.query('users', limit: 1);
    if (rows.isEmpty) return null;
    return rows.first['id'] as int?;
  }
}

class AuditHelper {
  static Future<void> write(
    DatabaseExecutor ex, {
    required String action,
    String? entityType,
    int? entityId,
    String? metadata,
    int? userId,
  }) {
    return ex.insert('audit_logs', {
      'action': action,
      'entity_type': entityType,
      'entity_id': entityId,
      'metadata': metadata,
      'created_at': nowMillis(),
      'user_id': userId,
    });
  }

  static Future<void> saleCreated(DatabaseExecutor ex, int invoiceId) {
    return write(
      ex,
      action: AuditActions.saleCreated,
      entityType: 'invoice',
      entityId: invoiceId,
    );
  }
}

import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/store_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart' as app_exceptions;
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:sqflite/sqflite.dart';

class StockRepository {
  StockRepository(this._db);

  final AppDatabase _db;

  Future<void> addStock({
    required int productId,
    required int quantity,
    int? unitCost,
    String? note,
  }) async {
    if (quantity <= 0) return;
    await _db.transaction((txn) async {
      await _applyDelta(
        txn,
        productId: productId,
        delta: quantity,
        type: StockTxn.purchase,
        note: note,
        unitCost: unitCost,
      );
      if (unitCost != null) {
        await txn.update(
          'products',
          {
            'purchase_price': unitCost,
            'updated_at': nowMillis(),
          },
          where: 'id = ?',
          whereArgs: [productId],
        );
      }
    });
  }

  Future<void> adjustStock({
    required int productId,
    required int delta,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw const app_exceptions.ValidationException(
        'Reason required',
        field: 'reason',
      );
    }
    await _db.transaction((txn) async {
      await _applyDelta(
        txn,
        productId: productId,
        delta: delta,
        type: StockTxn.adjustment,
        note: reason.trim(),
      );
      await AuditHelper.write(
        txn,
        action: AuditActions.stockAdjusted,
        entityType: 'product',
        entityId: productId,
        metadata: reason.trim(),
      );
    });
  }

  Future<List<StockMovement>> history({
    int? productId,
    StockHistoryFilter filter = StockHistoryFilter.all,
    String? query,
    int limit = 200,
  }) async {
    final clauses = <String>[];
    final args = <Object?>[];

    if (productId != null) {
      clauses.add('s.product_id = ?');
      args.add(productId);
    }

    switch (filter) {
      case StockHistoryFilter.stockIn:
        clauses.add('s.quantity > 0');
      case StockHistoryFilter.stockOut:
        clauses.add('s.quantity < 0');
      case StockHistoryFilter.all:
        break;
    }

    final q = query?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      clauses.add(
        '(LOWER(p.name) LIKE ? OR LOWER(IFNULL(p.sku, "")) LIKE ?)',
      );
      args
        ..add('%$q%')
        ..add('%$q%');
    }

    final where =
        clauses.isEmpty ? '' : 'WHERE ${clauses.join(' AND ')}';
    args.add(limit);

    final rows = await _db.db.rawQuery('''
SELECT
  s.*,
  p.name AS product_name,
  p.sku AS product_sku,
  p.unit AS product_unit,
  p.selling_price AS selling_price,
  CASE
    WHEN s.reference_type = 'invoice' THEN i.invoice_number
    ELSE NULL
  END AS reference_label
FROM stock_transactions s
JOIN products p ON p.id = s.product_id
LEFT JOIN invoices i
  ON s.reference_type = 'invoice' AND s.reference_id = i.id
$where
ORDER BY s.created_at DESC
LIMIT ?
''', args);
    return rows.map(StockMovement.fromMap).toList();
  }

  static Future<void> applyDelta(
    DatabaseExecutor txn, {
    required int productId,
    required int delta,
    required String type,
    String? note,
    int? unitCost,
    String? referenceType,
    int? referenceId,
  }) {
    return _applyDelta(
      txn,
      productId: productId,
      delta: delta,
      type: type,
      note: note,
      unitCost: unitCost,
      referenceType: referenceType,
      referenceId: referenceId,
    );
  }

  static Future<void> _applyDelta(
    DatabaseExecutor txn, {
    required int productId,
    required int delta,
    required String type,
    String? note,
    int? unitCost,
    String? referenceType,
    int? referenceId,
  }) async {
    final rows = await txn.query(
      'products',
      where: 'id = ?',
      whereArgs: [productId],
    );
    if (rows.isEmpty) {
      throw const app_exceptions.DatabaseException('Product not found');
    }
    final current = rows.first['current_stock'] as int;
    await txn.update(
      'products',
      {'current_stock': current + delta, 'updated_at': nowMillis()},
      where: 'id = ?',
      whereArgs: [productId],
    );
    await txn.insert('stock_transactions', {
      'product_id': productId,
      'transaction_type': type,
      'quantity': delta,
      'reference_type': referenceType,
      'reference_id': referenceId,
      'unit_cost': unitCost,
      'note': note,
      'created_at': nowMillis(),
    });
  }
}

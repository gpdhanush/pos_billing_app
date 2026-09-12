import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';

enum PremiumQuotaKind { products, stocks, expenses }

class PremiumAccess {
  PremiumAccess(this._db);

  final AppDatabase _db;

  Future<int> productCount(int storeId) async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS c FROM products WHERE store_id = ? AND is_active = 1',
      [storeId],
    );
    return rows.first['c'] as int? ?? 0;
  }

  Future<int> expenseCount(int storeId) async {
    final rows = await _db.db.rawQuery(
      'SELECT COUNT(*) AS c FROM expenses WHERE store_id = ?',
      [storeId],
    );
    return rows.first['c'] as int? ?? 0;
  }

  /// Manual stock in/out movements (not sales or opening).
  Future<int> stockMovementCount(int storeId) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT COUNT(*) AS c
FROM stock_transactions s
JOIN products p ON p.id = s.product_id
WHERE p.store_id = ?
  AND s.transaction_type IN (?, ?)
''',
      [storeId, StockTxn.purchase, StockTxn.adjustment],
    );
    return rows.first['c'] as int? ?? 0;
  }

  Future<int> countFor(PremiumQuotaKind kind, int storeId) {
    switch (kind) {
      case PremiumQuotaKind.products:
        return productCount(storeId);
      case PremiumQuotaKind.stocks:
        return stockMovementCount(storeId);
      case PremiumQuotaKind.expenses:
        return expenseCount(storeId);
    }
  }

  Future<bool> underFreeLimit(PremiumQuotaKind kind, int storeId) async {
    final count = await countFor(kind, storeId);
    return count < PremiumLimits.freeItemLimit;
  }
}

final premiumAccessProvider = Provider<PremiumAccess>((ref) {
  return PremiumAccess(ref.watch(databaseProvider));
});

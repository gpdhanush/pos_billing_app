import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/models.dart';

class ExpenseRepository {
  ExpenseRepository(this._db);

  final AppDatabase _db;

  Future<List<Expense>> list(int storeId, {int limit = 100}) async {
    final rows = await _db.db.query(
      'expenses',
      where: 'store_id = ?',
      whereArgs: [storeId],
      orderBy: 'spent_at DESC',
      limit: limit,
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<int> create({
    required int storeId,
    required String category,
    required int amountPaise,
    required String paymentMethod,
    String? note,
    int? spentAt,
  }) {
    final now = nowMillis();
    return _db.db.insert('expenses', {
      'store_id': storeId,
      'category': category.trim(),
      'amount': amountPaise,
      'payment_method': paymentMethod,
      'note': note,
      'spent_at': spentAt ?? now,
      'created_at': now,
    });
  }

  Future<Expense?> getById(int id) async {
    final rows = await _db.db.query(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return Expense.fromMap(rows.first);
  }

  Future<void> update({
    required int id,
    required String category,
    required int amountPaise,
    required String paymentMethod,
    String? note,
  }) {
    return _db.db.update(
      'expenses',
      {
        'category': category.trim(),
        'amount': amountPaise,
        'payment_method': paymentMethod,
        'note': note,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(int id) {
    return _db.db.delete('expenses', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> total(int storeId, {int? startMs, int? endMs}) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT IFNULL(SUM(amount),0) AS total FROM expenses
WHERE store_id = ? AND spent_at >= ? AND spent_at < ?
''',
      [storeId, startMs ?? 0, endMs ?? nowMillis() + 1],
    );
    return rows.first['total'] as int;
  }
}

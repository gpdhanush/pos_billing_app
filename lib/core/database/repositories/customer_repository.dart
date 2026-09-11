import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/models.dart';

class CustomerRepository {
  CustomerRepository(this._db);

  final AppDatabase _db;

  Future<List<Customer>> search(int storeId, String query, {int limit = 50}) async {
    final q = query.trim();
    final where = StringBuffer('store_id = ? AND is_active = 1');
    final args = <Object?>[storeId];
    if (q.isNotEmpty) {
      where.write(' AND (name LIKE ? OR IFNULL(phone,"") LIKE ?)');
      args.addAll(['%$q%', '%$q%']);
    }
    args.add(limit);
    final rows = await _db.db.rawQuery(
      'SELECT * FROM customers WHERE $where ORDER BY name COLLATE NOCASE LIMIT ?',
      args,
    );
    return rows.map(Customer.fromMap).toList();
  }

  Future<Customer?> get(int id) async {
    final rows = await _db.db.query('customers', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return Customer.fromMap(rows.first);
  }

  Future<Customer> create({
    required int storeId,
    required String name,
    String? phone,
    String? email,
    String? address,
    int creditLimitPaise = 0,
    int openingBalancePaise = 0,
    String? notes,
  }) async {
    final now = nowMillis();
    final id = await _db.db.insert('customers', {
      'store_id': storeId,
      'name': name.trim(),
      'phone': phone,
      'email': email,
      'address': address,
      'credit_limit': creditLimitPaise,
      'outstanding_balance': openingBalancePaise,
      'notes': notes,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    });
    return (await get(id))!;
  }

  Future<Customer> update(Customer customer) async {
    await _db.db.update(
      'customers',
      {
        'name': customer.name.trim(),
        'phone': customer.phone,
        'email': customer.email,
        'address': customer.address,
        'credit_limit': customer.creditLimitPaise,
        'notes': customer.notes,
        'is_active': customer.isActive ? 1 : 0,
        'updated_at': nowMillis(),
      },
      where: 'id = ?',
      whereArgs: [customer.id],
    );
    return (await get(customer.id))!;
  }

  Future<void> deactivate(int id) async {
    await _db.db.update(
      'customers',
      {'is_active': 0, 'updated_at': nowMillis()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/store_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart' as app_exceptions;
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:sqflite/sqflite.dart';

class ProductQuery {
  const ProductQuery({
    this.search,
    this.categoryId,
    this.lowStockOnly = false,
    this.outOfStockOnly = false,
    this.activeOnly = true,
    this.inactiveOnly = false,
    this.limit = 50,
    this.offset = 0,
  });

  final String? search;
  final int? categoryId;
  final bool lowStockOnly;
  final bool outOfStockOnly;
  final bool activeOnly;
  final bool inactiveOnly;
  final int limit;
  final int offset;
}

class ProductDraft {
  const ProductDraft({
    required this.storeId,
    required this.name,
    this.sku,
    this.categoryId,
    this.unit = 'pcs',
    this.purchasePricePaise = 0,
    this.sellingPricePaise = 0,
    this.taxRateBp = 0,
    this.minimumStock = 0,
    this.openingStock = 0,
    this.imagePath,
    this.barcodes = const [],
  });

  final int storeId;
  final String name;
  final String? sku;
  final int? categoryId;
  final String unit;
  final int purchasePricePaise;
  final int sellingPricePaise;
  final int taxRateBp;
  final int minimumStock;
  final int openingStock;
  final String? imagePath;
  final List<String> barcodes;
}

class ProductRepository {
  ProductRepository(this._db);

  final AppDatabase _db;

  Future<List<Category>> getCategories(int storeId) async {
    final rows = await _db.db.query(
      'categories',
      where: 'store_id = ? AND is_active = 1',
      whereArgs: [storeId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Category.fromMap).toList();
  }

  Future<int> addCategory(int storeId, String name) async {
    return _db.db.insert('categories', {
      'store_id': storeId,
      'name': name.trim(),
      'is_active': 1,
      'created_at': nowMillis(),
      'updated_at': nowMillis(),
    });
  }

  Future<void> renameCategory(int id, String name) async {
    await _db.db.update(
      'categories',
      {'name': name.trim(), 'updated_at': nowMillis()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deactivateCategory(int id) async {
    await _db.db.update(
      'categories',
      {'is_active': 0, 'updated_at': nowMillis()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getProducts(int storeId, ProductQuery query) async {
    final where = StringBuffer('p.store_id = ?');
    final args = <Object?>[storeId];
    if (query.inactiveOnly) {
      where.write(' AND p.is_active = 0');
    } else if (query.activeOnly) {
      where.write(' AND p.is_active = 1');
    }
    if (query.categoryId != null) {
      where.write(' AND p.category_id = ?');
      args.add(query.categoryId);
    }
    if (query.lowStockOnly) {
      where.write(' AND p.current_stock <= p.minimum_stock');
    }
    if (query.outOfStockOnly) {
      where.write(' AND p.current_stock <= 0');
    }
    final search = query.search?.trim();
    if (search != null && search.isNotEmpty) {
      where.write(
        ' AND (p.name LIKE ? OR IFNULL(p.sku,"") LIKE ? OR EXISTS (SELECT 1 FROM product_barcodes b WHERE b.product_id = p.id AND b.barcode LIKE ?))',
      );
      final like = '%$search%';
      args.addAll([like, like, like]);
    }
    args.addAll([query.limit, query.offset]);
    final rows = await _db.db.rawQuery('''
SELECT p.*, c.name AS category_name
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
WHERE $where
ORDER BY p.name COLLATE NOCASE
LIMIT ? OFFSET ?
''', args);
    final products = <Product>[];
    for (final row in rows) {
      final barcodes = await _barcodesFor(row['id'] as int);
      products.add(Product.fromMap(row, barcodes: barcodes));
    }
    return products;
  }

  Future<Product?> getProduct(int id) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT p.*, c.name AS category_name
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
WHERE p.id = ?
''',
      [id],
    );
    if (rows.isEmpty) return null;
    return Product.fromMap(rows.first, barcodes: await _barcodesFor(id));
  }

  Future<Product?> getProductByBarcode(String barcode) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT p.*, c.name AS category_name
FROM product_barcodes b
JOIN products p ON p.id = b.product_id
LEFT JOIN categories c ON c.id = p.category_id
WHERE b.barcode = ? AND p.is_active = 1
LIMIT 1
''',
      [barcode.trim()],
    );
    if (rows.isEmpty) return null;
    final id = rows.first['id'] as int;
    return Product.fromMap(rows.first, barcodes: await _barcodesFor(id));
  }

  Future<Product> createProduct(ProductDraft draft) async {
    return _db
        .transaction((txn) async {
          await _assertBarcodesFree(txn, draft.barcodes);
          final now = nowMillis();
          final id = await txn.insert('products', {
            'store_id': draft.storeId,
            'name': draft.name.trim(),
            'sku': _emptyToNull(draft.sku),
            'category_id': draft.categoryId,
            'unit': draft.unit,
            'purchase_price': draft.purchasePricePaise,
            'selling_price': draft.sellingPricePaise,
            'tax_rate': draft.taxRateBp,
            'minimum_stock': draft.minimumStock,
            'current_stock': draft.openingStock,
            'image_path': draft.imagePath,
            'is_active': 1,
            'created_at': now,
            'updated_at': now,
          });
          for (final code in draft.barcodes.where((e) => e.trim().isNotEmpty)) {
            await txn.insert('product_barcodes', {
              'product_id': id,
              'barcode': code.trim(),
              'created_at': now,
            });
          }
          if (draft.openingStock != 0) {
            await txn.insert('stock_transactions', {
              'product_id': id,
              'transaction_type': StockTxn.opening,
              'quantity': draft.openingStock,
              'reference_type': 'product',
              'reference_id': id,
              'unit_cost': draft.purchasePricePaise,
              'note': 'Opening stock',
              'created_at': now,
            });
          }
          await AuditHelper.write(
            txn,
            action: AuditActions.productCreated,
            entityType: 'product',
            entityId: id,
          );
          return id;
        })
        .then(getProduct)
        .then((p) => p!);
  }

  Future<Product> updateProduct(
    Product product, {
    List<String>? barcodes,
  }) async {
    return _db
        .transaction((txn) async {
          final existing = await txn.query(
            'products',
            where: 'id = ?',
            whereArgs: [product.id],
          );
          if (existing.isEmpty) {
            throw const app_exceptions.DatabaseException('Product not found');
          }
          final oldPrice = existing.first['selling_price'] as int;
          if (barcodes != null) {
            await _assertBarcodesFree(
              txn,
              barcodes,
              excludeProductId: product.id,
            );
          }
          await txn.update(
            'products',
            {
              'name': product.name.trim(),
              'sku': _emptyToNull(product.sku),
              'category_id': product.categoryId,
              'unit': product.unit,
              'purchase_price': product.purchasePricePaise,
              'selling_price': product.sellingPricePaise,
              'tax_rate': product.taxRateBp,
              'minimum_stock': product.minimumStock,
              'image_path': product.imagePath,
              'is_active': boolToInt(product.isActive),
              'updated_at': nowMillis(),
            },
            where: 'id = ?',
            whereArgs: [product.id],
          );
          if (barcodes != null) {
            await txn.delete(
              'product_barcodes',
              where: 'product_id = ?',
              whereArgs: [product.id],
            );
            for (final code in barcodes.where((e) => e.trim().isNotEmpty)) {
              await txn.insert('product_barcodes', {
                'product_id': product.id,
                'barcode': code.trim(),
                'created_at': nowMillis(),
              });
            }
          }
          if (oldPrice != product.sellingPricePaise) {
            await AuditHelper.write(
              txn,
              action: AuditActions.priceChanged,
              entityType: 'product',
              entityId: product.id,
              metadata: '$oldPrice->${product.sellingPricePaise}',
            );
          }
          await AuditHelper.write(
            txn,
            action: AuditActions.productUpdated,
            entityType: 'product',
            entityId: product.id,
          );
          return product.id;
        })
        .then(getProduct)
        .then((p) => p!);
  }

  Future<void> deactivateProduct(int id) async {
    await _db.db.update(
      'products',
      {'is_active': 0, 'updated_at': nowMillis()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> activateProduct(int id) async {
    await _db.db.update(
      'products',
      {'is_active': 1, 'updated_at': nowMillis()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<String>> _barcodesFor(int productId) async {
    final rows = await _db.db.query(
      'product_barcodes',
      where: 'product_id = ?',
      whereArgs: [productId],
    );
    return rows.map((e) => e['barcode'] as String).toList();
  }

  Future<void> _assertBarcodesFree(
    DatabaseExecutor txn,
    List<String> barcodes, {
    int? excludeProductId,
  }) async {
    for (final raw in barcodes) {
      final code = raw.trim();
      if (code.isEmpty) continue;
      final rows = await txn.query(
        'product_barcodes',
        where: excludeProductId == null
            ? 'barcode = ?'
            : 'barcode = ? AND product_id != ?',
        whereArgs: excludeProductId == null ? [code] : [code, excludeProductId],
      );
      if (rows.isNotEmpty) {
        throw const app_exceptions.DuplicateBarcodeException();
      }
    }
  }

  String? _emptyToNull(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}

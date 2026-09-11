import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/money/money.dart';
import 'package:share_plus/share_plus.dart';

enum DataExportKind { products, orders, customers, stocks, all }

class DataExportService {
  DataExportService(this._db);

  final AppDatabase _db;

  Future<void> exportAndShare({
    required int storeId,
    required DataExportKind kind,
  }) async {
    final stamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final dir = await getTemporaryDirectory();

    if (kind == DataExportKind.all) {
      final files = {
        'products.csv': await _productsCsv(storeId),
        'orders.csv': await _ordersCsv(storeId),
        'order_items.csv': await _orderItemsCsv(storeId),
        'customers.csv': await _customersCsv(storeId),
        'stocks.csv': await _stocksCsv(storeId),
      };
      final archive = Archive();
      for (final entry in files.entries) {
        final bytes = utf8.encode(entry.value);
        archive.addFile(ArchiveFile(entry.key, bytes.length, bytes));
      }
      final zipped = ZipEncoder().encode(archive);
      final path = p.join(dir.path, 'pos_export_$stamp.zip');
      final file = File(path)..writeAsBytesSync(zipped);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'application/zip')],
          subject: 'POS Billing export',
          text: 'Full POS Billing data export',
        ),
      );
      return;
    }

    late final String name;
    late final String csv;
    switch (kind) {
      case DataExportKind.products:
        name = 'products';
        csv = await _productsCsv(storeId);
      case DataExportKind.orders:
        name = 'orders';
        csv = await _ordersCsv(storeId);
      case DataExportKind.customers:
        name = 'customers';
        csv = await _customersCsv(storeId);
      case DataExportKind.stocks:
        name = 'stocks';
        csv = await _stocksCsv(storeId);
      case DataExportKind.all:
        return;
    }

    final path = p.join(dir.path, '${name}_$stamp.csv');
    final file = File(path)..writeAsStringSync(csv, encoding: utf8);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: 'POS Billing $name export',
        text: 'Exported $name data',
      ),
    );
  }

  Future<String> _productsCsv(int storeId) async {
    final rows = await _db.db.rawQuery('''
SELECT
  p.name,
  p.sku,
  c.name AS category,
  p.unit,
  p.purchase_price,
  p.selling_price,
  p.current_stock,
  p.minimum_stock,
  p.tax_rate,
  p.is_active,
  (
    SELECT GROUP_CONCAT(b.barcode, '|')
    FROM product_barcodes b
    WHERE b.product_id = p.id
  ) AS barcodes
FROM products p
LEFT JOIN categories c ON c.id = p.category_id
WHERE p.store_id = ?
ORDER BY p.name COLLATE NOCASE
''', [storeId]);

    final buf = StringBuffer()
      ..writeln(
        _csvRow([
          'name',
          'sku',
          'category',
          'unit',
          'purchase_price',
          'selling_price',
          'current_stock',
          'minimum_stock',
          'tax_rate_bp',
          'is_active',
          'barcodes',
        ]),
      );
    for (final r in rows) {
      buf.writeln(
        _csvRow([
          r['name'],
          r['sku'],
          r['category'],
          r['unit'],
          _rupees(r['purchase_price'] as int?),
          _rupees(r['selling_price'] as int?),
          r['current_stock'],
          r['minimum_stock'],
          r['tax_rate'],
          (r['is_active'] as int?) == 1 ? 'yes' : 'no',
          r['barcodes'],
        ]),
      );
    }
    return buf.toString();
  }

  Future<String> _ordersCsv(int storeId) async {
    final rows = await _db.db.rawQuery('''
SELECT
  i.invoice_number,
  i.status,
  i.created_at,
  c.name AS customer_name,
  i.subtotal,
  i.discount,
  i.tax,
  i.total,
  i.note,
  (
    SELECT GROUP_CONCAT(p.payment_method || ':' || p.amount, '|')
    FROM payments p
    WHERE p.invoice_id = i.id
  ) AS payments
FROM invoices i
LEFT JOIN customers c ON c.id = i.customer_id
WHERE i.store_id = ?
ORDER BY i.created_at DESC
''', [storeId]);

    final buf = StringBuffer()
      ..writeln(
        _csvRow([
          'invoice_number',
          'status',
          'created_at',
          'customer',
          'subtotal',
          'discount',
          'tax',
          'total',
          'payments',
          'note',
        ]),
      );
    for (final r in rows) {
      buf.writeln(
        _csvRow([
          r['invoice_number'],
          r['status'],
          _dt(r['created_at'] as int?),
          r['customer_name'],
          _rupees(r['subtotal'] as int?),
          _rupees(r['discount'] as int?),
          _rupees(r['tax'] as int?),
          _rupees(r['total'] as int?),
          _paymentsLabel(r['payments'] as String?),
          r['note'],
        ]),
      );
    }
    return buf.toString();
  }

  Future<String> _orderItemsCsv(int storeId) async {
    final rows = await _db.db.rawQuery('''
SELECT
  i.invoice_number,
  ii.product_name_snapshot,
  ii.barcode_snapshot,
  ii.quantity,
  ii.unit_price,
  ii.discount,
  ii.tax,
  ii.total
FROM invoice_items ii
JOIN invoices i ON i.id = ii.invoice_id
WHERE i.store_id = ?
ORDER BY i.created_at DESC, ii.id ASC
''', [storeId]);

    final buf = StringBuffer()
      ..writeln(
        _csvRow([
          'invoice_number',
          'product',
          'barcode',
          'quantity',
          'unit_price',
          'discount',
          'tax',
          'line_total',
        ]),
      );
    for (final r in rows) {
      buf.writeln(
        _csvRow([
          r['invoice_number'],
          r['product_name_snapshot'],
          r['barcode_snapshot'],
          r['quantity'],
          _rupees(r['unit_price'] as int?),
          _rupees(r['discount'] as int?),
          _rupees(r['tax'] as int?),
          _rupees(r['total'] as int?),
        ]),
      );
    }
    return buf.toString();
  }

  Future<String> _customersCsv(int storeId) async {
    final rows = await _db.db.rawQuery('''
SELECT name, phone, email, address, credit_limit, outstanding_balance, notes, is_active
FROM customers
WHERE store_id = ?
ORDER BY name COLLATE NOCASE
''', [storeId]);

    final buf = StringBuffer()
      ..writeln(
        _csvRow([
          'name',
          'phone',
          'email',
          'address',
          'credit_limit',
          'outstanding_balance',
          'notes',
          'is_active',
        ]),
      );
    for (final r in rows) {
      buf.writeln(
        _csvRow([
          r['name'],
          r['phone'],
          r['email'],
          r['address'],
          _rupees(r['credit_limit'] as int?),
          _rupees(r['outstanding_balance'] as int?),
          r['notes'],
          (r['is_active'] as int?) == 1 ? 'yes' : 'no',
        ]),
      );
    }
    return buf.toString();
  }

  Future<String> _stocksCsv(int storeId) async {
    final rows = await _db.db.rawQuery('''
SELECT
  s.created_at,
  p.name AS product_name,
  p.sku,
  s.transaction_type,
  s.quantity,
  s.unit_cost,
  s.reference_type,
  s.reference_id,
  i.invoice_number,
  s.note
FROM stock_transactions s
JOIN products p ON p.id = s.product_id
LEFT JOIN invoices i
  ON s.reference_type = 'invoice' AND s.reference_id = i.id
WHERE p.store_id = ?
ORDER BY s.created_at DESC
''', [storeId]);

    final buf = StringBuffer()
      ..writeln(
        _csvRow([
          'created_at',
          'product',
          'sku',
          'type',
          'quantity',
          'unit_cost',
          'reference_type',
          'reference_id',
          'invoice_number',
          'note',
        ]),
      );
    for (final r in rows) {
      buf.writeln(
        _csvRow([
          _dt(r['created_at'] as int?),
          r['product_name'],
          r['sku'],
          r['transaction_type'],
          r['quantity'],
          _rupees(r['unit_cost'] as int?),
          r['reference_type'],
          r['reference_id'],
          r['invoice_number'],
          r['note'],
        ]),
      );
    }
    return buf.toString();
  }

  String _rupees(int? paise) {
    if (paise == null) return '';
    return Money(paise).rupees.toStringAsFixed(2);
  }

  String _dt(int? ms) {
    if (ms == null) return '';
    return DateFormat('yyyy-MM-dd HH:mm:ss').format(
      DateTime.fromMillisecondsSinceEpoch(ms),
    );
  }

  String _paymentsLabel(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.split('|').map((part) {
      final bits = part.split(':');
      if (bits.length < 2) return part;
      final amount = int.tryParse(bits[1]);
      if (amount == null) return part;
      return '${bits[0]}:${Money(amount).rupees.toStringAsFixed(2)}';
    }).join('|');
  }

  String _csvRow(List<Object?> values) {
    return values.map(_escape).join(',');
  }

  String _escape(Object? value) {
    final text = value?.toString() ?? '';
    if (text.contains(',') ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r')) {
      return '"${text.replaceAll('"', '""')}"';
    }
    return text;
  }
}

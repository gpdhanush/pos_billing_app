import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/stock_repository.dart';
import 'package:pos_billing/core/database/repositories/store_repository.dart';
import 'package:pos_billing/core/errors/app_exception.dart' as app_exceptions;
import 'package:pos_billing/core/money/billing_calculation_service.dart';
import 'package:pos_billing/core/utils/invoice_numbering.dart';
import 'package:pos_billing/core/utils/time.dart';
import 'package:pos_billing/shared/models/models.dart';

class CartLine {
  const CartLine({
    required this.product,
    required this.quantity,
    this.itemDiscountPaise = 0,
    this.barcode,
  });

  final Product product;
  final int quantity;
  final int itemDiscountPaise;
  final String? barcode;

  CartLine copyWith({int? quantity, int? itemDiscountPaise}) => CartLine(
    product: product,
    quantity: quantity ?? this.quantity,
    itemDiscountPaise: itemDiscountPaise ?? this.itemDiscountPaise,
    barcode: barcode,
  );
}

class PaymentDraft {
  const PaymentDraft({
    required this.method,
    required this.amountPaise,
    this.receivedPaise,
    this.changePaise,
  });

  final String method;
  final int amountPaise;
  final int? receivedPaise;
  final int? changePaise;
}

class CheckoutCommand {
  const CheckoutCommand({
    required this.storeId,
    required this.lines,
    required this.payments,
    this.customerId,
    this.billDiscountPaise = 0,
    this.taxOverridePaise,
    this.allowNegativeStock = false,
  });

  final int storeId;
  final List<CartLine> lines;
  final List<PaymentDraft> payments;
  final int? customerId;
  final int billDiscountPaise;
  final int? taxOverridePaise;
  final bool allowNegativeStock;
}

class SalesDateRange {
  const SalesDateRange(this.startMs, this.endMs);

  final int startMs;
  final int endMs;

  factory SalesDateRange.today([DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, n.day);
    final end = start.add(const Duration(days: 1));
    return SalesDateRange(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );
  }

  factory SalesDateRange.yesterday([DateTime? now]) {
    final today = SalesDateRange.today(now);
    return SalesDateRange(
      today.startMs - const Duration(days: 1).inMilliseconds,
      today.startMs,
    );
  }

  factory SalesDateRange.thisWeek([DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = DateTime(
      n.year,
      n.month,
      n.day,
    ).subtract(Duration(days: n.weekday - DateTime.monday));
    return SalesDateRange(
      start.millisecondsSinceEpoch,
      start.add(const Duration(days: 7)).millisecondsSinceEpoch,
    );
  }

  factory SalesDateRange.thisMonth([DateTime? now]) {
    final n = now ?? DateTime.now();
    final start = DateTime(n.year, n.month, 1);
    final end = (n.month == 12)
        ? DateTime(n.year + 1, 1, 1)
        : DateTime(n.year, n.month + 1, 1);
    return SalesDateRange(
      start.millisecondsSinceEpoch,
      end.millisecondsSinceEpoch,
    );
  }

  /// Inclusive calendar days from [start] through [end].
  factory SalesDateRange.custom(DateTime start, DateTime end) {
    final from = DateTime(start.year, start.month, start.day);
    final toExclusive = DateTime(end.year, end.month, end.day)
        .add(const Duration(days: 1));
    return SalesDateRange(
      from.millisecondsSinceEpoch,
      toExclusive.millisecondsSinceEpoch,
    );
  }
}

class SalesRepository {
  SalesRepository(
    this._db, {
    this.calculator = const BillingCalculationService(),
  });

  final AppDatabase _db;
  final BillingCalculationService calculator;

  Future<InvoiceDetail> checkout(CheckoutCommand command) async {
    if (command.lines.isEmpty) {
      throw const app_exceptions.ValidationException('Cart is empty');
    }
    final creditAmount = command.payments
        .where((p) => p.method == PaymentMethods.credit)
        .fold<int>(0, (a, b) => a + b.amountPaise);
    if (creditAmount > 0 && command.customerId == null) {
      throw const app_exceptions.ValidationException(
        'Customer required for credit',
      );
    }

    var calc = calculator.calculate(
      lines: [
        for (final line in command.lines)
          LineCalcInput(
            unitPricePaise: line.product.sellingPricePaise,
            quantity: line.quantity,
            itemDiscountPaise: line.itemDiscountPaise,
            taxRateBp: line.product.taxRateBp,
          ),
      ],
      billDiscountPaise: command.billDiscountPaise,
    );
    if (command.taxOverridePaise != null) {
      calc = calculator.applyTaxOverride(calc, command.taxOverridePaise!);
    }

    final paid = calculator.calculatePaidAmount(
      command.payments.map((e) => e.amountPaise).toList(),
    );
    if (paid != calc.grandTotalPaise) {
      throw const app_exceptions.ValidationException(
        'Paid amount must equal total',
      );
    }

    return _db
        .transaction((txn) async {
          for (final line in command.lines) {
            final rows = await txn.query(
              'products',
              where: 'id = ?',
              whereArgs: [line.product.id],
            );
            if (rows.isEmpty) {
              throw const app_exceptions.DatabaseException('Product missing');
            }
            final stock = rows.first['current_stock'] as int;
            if (!command.allowNegativeStock && stock < line.quantity) {
              throw app_exceptions.InsufficientStockException(
                line.product.name,
              );
            }
          }

          final storeRows = await txn.query(
            'stores',
            columns: ['invoice_prefix', 'next_invoice_number'],
            where: 'id = ?',
            whereArgs: [command.storeId],
          );
          final prefix =
              (storeRows.first['invoice_prefix'] as String?) ?? 'INV';
          final number = (storeRows.first['next_invoice_number'] as int?) ?? 1;
          await txn.update(
            'stores',
            {'next_invoice_number': number + 1, 'updated_at': nowMillis()},
            where: 'id = ?',
            whereArgs: [command.storeId],
          );
          final invoiceNumber = InvoiceNumbering.format(
            prefix: prefix,
            number: number,
          );

          final now = nowMillis();
          final invoiceId = await txn.insert('invoices', {
            'store_id': command.storeId,
            'invoice_number': invoiceNumber,
            'customer_id': command.customerId,
            'subtotal': calc.subtotalPaise,
            'discount': calc.discountPaise,
            'tax': calc.taxPaise,
            'total': calc.grandTotalPaise,
            'status': InvoiceStatus.completed,
            'created_at': now,
            'updated_at': now,
          });

          for (var i = 0; i < command.lines.length; i++) {
            final line = command.lines[i];
            final lineCalc = calc.lines[i];
            await txn.insert('invoice_items', {
              'invoice_id': invoiceId,
              'product_id': line.product.id,
              'product_name_snapshot': line.product.name,
              'barcode_snapshot': line.barcode ?? line.product.primaryBarcode,
              'quantity': line.quantity,
              'unit_price': line.product.sellingPricePaise,
              'discount':
                  lineCalc.itemDiscountPaise + lineCalc.billDiscountSharePaise,
              'tax': lineCalc.taxPaise,
              'total': lineCalc.totalPaise,
            });
            await StockRepository.applyDelta(
              txn,
              productId: line.product.id,
              delta: -line.quantity,
              type: StockTxn.sale,
              referenceType: 'invoice',
              referenceId: invoiceId,
            );
          }

          for (final payment in command.payments) {
            await txn.insert('payments', {
              'invoice_id': invoiceId,
              'payment_method': payment.method,
              'amount': payment.amountPaise,
              'received_amount': payment.receivedPaise,
              'change_amount': payment.changePaise,
              'created_at': now,
            });
          }

          if (creditAmount > 0) {
            final customers = await txn.query(
              'customers',
              where: 'id = ?',
              whereArgs: [command.customerId],
            );
            final current = customers.first['outstanding_balance'] as int;
            await txn.update(
              'customers',
              {
                'outstanding_balance': current + creditAmount,
                'updated_at': now,
              },
              where: 'id = ?',
              whereArgs: [command.customerId],
            );
          }

          await AuditHelper.write(
            txn,
            action: AuditActions.saleCreated,
            entityType: 'invoice',
            entityId: invoiceId,
          );
          await AuditHelper.write(
            txn,
            action: AuditActions.paymentReceived,
            entityType: 'invoice',
            entityId: invoiceId,
          );

          return invoiceId;
        })
        .then(getInvoice)
        .then((v) => v!);
  }

  Future<InvoiceDetail?> getInvoice(int id) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT i.*, c.name AS customer_name
FROM invoices i
LEFT JOIN customers c ON c.id = i.customer_id
WHERE i.id = ?
''',
      [id],
    );
    if (rows.isEmpty) return null;
    final items = await _db.db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    final payments = await _db.db.query(
      'payments',
      where: 'invoice_id = ?',
      whereArgs: [id],
    );
    final summary = InvoiceSummary.fromMap(rows.first);
    return InvoiceDetail(
      summary: summary,
      subtotalPaise: rows.first['subtotal'] as int,
      discountPaise: rows.first['discount'] as int,
      taxPaise: rows.first['tax'] as int,
      note: rows.first['note'] as String?,
      originalInvoiceId: rows.first['original_invoice_id'] as int?,
      items: items.map(InvoiceLine.fromMap).toList(),
      payments: payments.map(PaymentRecord.fromMap).toList(),
    );
  }

  Future<List<InvoiceSummary>> listSales({
    required int storeId,
    required SalesDateRange range,
    String? paymentMethod,
    int? customerId,
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final where = StringBuffer(
      'i.store_id = ? AND i.created_at >= ? AND i.created_at < ?',
    );
    final args = <Object?>[storeId, range.startMs, range.endMs];
    if (customerId != null) {
      where.write(' AND i.customer_id = ?');
      args.add(customerId);
    }
    if (status != null) {
      where.write(' AND i.status = ?');
      args.add(status);
    }
    if (paymentMethod != null) {
      where.write(
        ' AND EXISTS (SELECT 1 FROM payments p WHERE p.invoice_id = i.id AND p.payment_method = ?)',
      );
      args.add(paymentMethod);
    }
    args.addAll([limit, offset]);
    final rows = await _db.db.rawQuery('''
SELECT i.*, c.name AS customer_name,
  (SELECT GROUP_CONCAT(DISTINCT p.payment_method) FROM payments p WHERE p.invoice_id = i.id) AS payment_methods
FROM invoices i
LEFT JOIN customers c ON c.id = i.customer_id
WHERE $where
ORDER BY i.created_at DESC
LIMIT ? OFFSET ?
''', args);
    return rows.map(InvoiceSummary.fromMap).toList();
  }

  Future<InvoiceDetail> reverseSale({
    required int invoiceId,
    required bool asRefund,
  }) async {
    final original = await getInvoice(invoiceId);
    if (original == null) {
      throw const app_exceptions.DatabaseException('Invoice not found');
    }
    if (original.summary.status != InvoiceStatus.completed) {
      throw const app_exceptions.ValidationException(
        'Invoice already reversed',
      );
    }

    return _db
        .transaction((txn) async {
          final now = nowMillis();
          final storeRows = await txn.query(
            'stores',
            columns: ['id', 'invoice_prefix', 'next_invoice_number'],
            where: 'id = (SELECT store_id FROM invoices WHERE id = ?)',
            whereArgs: [invoiceId],
          );
          final storeId = storeRows.first['id'] as int;
          final prefix = storeRows.first['invoice_prefix'] as String? ?? 'INV';
          final number = storeRows.first['next_invoice_number'] as int? ?? 1;
          await txn.update(
            'stores',
            {'next_invoice_number': number + 1, 'updated_at': now},
            where: 'id = ?',
            whereArgs: [storeId],
          );
          final reversalNumber = InvoiceNumbering.format(
            prefix: prefix,
            number: number,
          );
          final reversalId = await txn.insert('invoices', {
            'store_id': storeId,
            'invoice_number': reversalNumber,
            'customer_id': original.summary.customerId,
            'subtotal': -original.subtotalPaise,
            'discount': -original.discountPaise,
            'tax': -original.taxPaise,
            'total': -original.summary.totalPaise,
            'status': asRefund
                ? InvoiceStatus.refunded
                : InvoiceStatus.cancelled,
            'original_invoice_id': invoiceId,
            'created_at': now,
            'updated_at': now,
          });

          for (final item in original.items) {
            await txn.insert('invoice_items', {
              'invoice_id': reversalId,
              'product_id': item.productId,
              'product_name_snapshot': item.name,
              'barcode_snapshot': item.barcode,
              'quantity': -item.quantity,
              'unit_price': item.unitPricePaise,
              'discount': -item.discountPaise,
              'tax': -item.taxPaise,
              'total': -item.totalPaise,
            });
            if (item.productId != null) {
              await StockRepository.applyDelta(
                txn,
                productId: item.productId!,
                delta: item.quantity,
                type: StockTxn.refund,
                referenceType: 'invoice',
                referenceId: reversalId,
                note: asRefund ? 'Refund' : 'Cancellation',
              );
            }
          }

          for (final payment in original.payments) {
            await txn.insert('payments', {
              'invoice_id': reversalId,
              'payment_method': payment.method,
              'amount': -payment.amountPaise,
              'created_at': now,
            });
            if (payment.method == PaymentMethods.credit &&
                original.summary.customerId != null) {
              final customers = await txn.query(
                'customers',
                where: 'id = ?',
                whereArgs: [original.summary.customerId],
              );
              final current = customers.first['outstanding_balance'] as int;
              await txn.update(
                'customers',
                {
                  'outstanding_balance': current - payment.amountPaise,
                  'updated_at': now,
                },
                where: 'id = ?',
                whereArgs: [original.summary.customerId],
              );
            }
          }

          await txn.update(
            'invoices',
            {
              'status': asRefund
                  ? InvoiceStatus.refunded
                  : InvoiceStatus.cancelled,
              'updated_at': now,
            },
            where: 'id = ?',
            whereArgs: [invoiceId],
          );
          await AuditHelper.write(
            txn,
            action: asRefund
                ? AuditActions.refundCreated
                : AuditActions.saleCancelled,
            entityType: 'invoice',
            entityId: invoiceId,
          );
          return reversalId;
        })
        .then(getInvoice)
        .then((v) => v!);
  }

  Future<DashboardStats> dashboardStats(int storeId) async {
    final today = SalesDateRange.today();
    final sales = await _db.db.rawQuery(
      '''
SELECT IFNULL(SUM(total),0) AS sales, COUNT(*) AS bills
FROM invoices
WHERE store_id = ? AND status = ? AND created_at >= ? AND created_at < ? AND total > 0
''',
      [storeId, InvoiceStatus.completed, today.startMs, today.endMs],
    );
    final stock = await _db.db.rawQuery(
      '''
SELECT IFNULL(SUM(current_stock),0) AS items,
  SUM(CASE WHEN current_stock <= minimum_stock THEN 1 ELSE 0 END) AS low
FROM products
WHERE store_id = ? AND is_active = 1
''',
      [storeId],
    );
    return DashboardStats(
      todaySalesPaise: sales.first['sales'] as int,
      billsToday: sales.first['bills'] as int,
      itemsInStock: stock.first['items'] as int,
      lowStockCount: (stock.first['low'] as int?) ?? 0,
    );
  }

  Future<Map<String, int>> paymentTotals(
    int storeId,
    SalesDateRange range,
  ) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT p.payment_method, IFNULL(SUM(p.amount),0) AS total
FROM payments p
JOIN invoices i ON i.id = p.invoice_id
WHERE i.store_id = ? AND i.created_at >= ? AND i.created_at < ? AND i.status = ?
GROUP BY p.payment_method
''',
      [storeId, range.startMs, range.endMs, InvoiceStatus.completed],
    );
    return {
      for (final row in rows)
        row['payment_method'] as String: row['total'] as int,
    };
  }

  Future<List<(String, int, int)>> topProducts(
    int storeId,
    SalesDateRange range, {
    int limit = 10,
  }) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT ii.product_name_snapshot AS name, SUM(ii.quantity) AS qty, SUM(ii.total) AS sales
FROM invoice_items ii
JOIN invoices i ON i.id = ii.invoice_id
WHERE i.store_id = ? AND i.created_at >= ? AND i.created_at < ? AND i.status = ? AND ii.quantity > 0
GROUP BY ii.product_name_snapshot
ORDER BY sales DESC
LIMIT ?
''',
      [storeId, range.startMs, range.endMs, InvoiceStatus.completed, limit],
    );
    return [
      for (final row in rows)
        (row['name'] as String, row['qty'] as int, row['sales'] as int),
    ];
  }

  Future<int> stockValuePaise(int storeId) async {
    final rows = await _db.db.rawQuery(
      '''
SELECT IFNULL(SUM(current_stock * purchase_price),0) AS value
FROM products WHERE store_id = ? AND is_active = 1
''',
      [storeId],
    );
    return rows.first['value'] as int;
  }

  Future<InvoiceDetail?> lastCompletedInvoice(int storeId) async {
    final rows = await _db.db.query(
      'invoices',
      where: 'store_id = ? AND status = ? AND total > 0',
      whereArgs: [storeId, InvoiceStatus.completed],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return getInvoice(rows.first['id'] as int);
  }
}

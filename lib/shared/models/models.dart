import 'package:pos_billing/core/utils/time.dart';

class Category {
  const Category({
    required this.id,
    required this.storeId,
    required this.name,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int storeId;
  final String name;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  factory Category.fromMap(Map<String, Object?> map) => Category(
        id: map['id'] as int,
        storeId: map['store_id'] as int,
        name: map['name'] as String,
        isActive: intToBool(map['is_active']),
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );
}

class Product {
  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.sku,
    this.categoryId,
    this.categoryName,
    this.unit = 'pcs',
    this.purchasePricePaise = 0,
    this.sellingPricePaise = 0,
    this.taxRateBp = 0,
    this.minimumStock = 0,
    this.currentStock = 0,
    this.imagePath,
    this.isActive = true,
    this.barcodes = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int storeId;
  final String name;
  final String? sku;
  final int? categoryId;
  final String? categoryName;
  final String unit;
  final int purchasePricePaise;
  final int sellingPricePaise;
  final int taxRateBp;
  final int minimumStock;
  final int currentStock;
  final String? imagePath;
  final bool isActive;
  final List<String> barcodes;
  final int createdAt;
  final int updatedAt;

  bool get isLowStock => currentStock <= minimumStock;
  bool get isOutOfStock => currentStock <= 0;
  String? get primaryBarcode => barcodes.isEmpty ? null : barcodes.first;

  factory Product.fromMap(Map<String, Object?> map, {List<String> barcodes = const []}) {
    return Product(
      id: map['id'] as int,
      storeId: map['store_id'] as int,
      name: map['name'] as String,
      sku: map['sku'] as String?,
      categoryId: map['category_id'] as int?,
      categoryName: map['category_name'] as String?,
      unit: (map['unit'] as String?) ?? 'pcs',
      purchasePricePaise: (map['purchase_price'] as int?) ?? 0,
      sellingPricePaise: (map['selling_price'] as int?) ?? 0,
      taxRateBp: (map['tax_rate'] as int?) ?? 0,
      minimumStock: (map['minimum_stock'] as int?) ?? 0,
      currentStock: (map['current_stock'] as int?) ?? 0,
      imagePath: map['image_path'] as String?,
      isActive: intToBool(map['is_active'] ?? 1),
      barcodes: barcodes,
      createdAt: map['created_at'] as int,
      updatedAt: map['updated_at'] as int,
    );
  }
}

class Customer {
  const Customer({
    required this.id,
    required this.storeId,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.creditLimitPaise = 0,
    this.outstandingBalancePaise = 0,
    this.notes,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final int id;
  final int storeId;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final int creditLimitPaise;
  final int outstandingBalancePaise;
  final String? notes;
  final bool isActive;
  final int createdAt;
  final int updatedAt;

  factory Customer.fromMap(Map<String, Object?> map) => Customer(
        id: map['id'] as int,
        storeId: map['store_id'] as int,
        name: map['name'] as String,
        phone: map['phone'] as String?,
        email: map['email'] as String?,
        address: map['address'] as String?,
        creditLimitPaise: (map['credit_limit'] as int?) ?? 0,
        outstandingBalancePaise: (map['outstanding_balance'] as int?) ?? 0,
        notes: map['notes'] as String?,
        isActive: intToBool(map['is_active'] ?? 1),
        createdAt: map['created_at'] as int,
        updatedAt: map['updated_at'] as int,
      );
}

class InvoiceSummary {
  const InvoiceSummary({
    required this.id,
    required this.invoiceNumber,
    this.customerId,
    this.customerName,
    required this.totalPaise,
    required this.status,
    required this.createdAt,
    this.paymentMethods = const [],
  });

  final int id;
  final String invoiceNumber;
  final int? customerId;
  final String? customerName;
  final int totalPaise;
  final String status;
  final int createdAt;
  final List<String> paymentMethods;

  factory InvoiceSummary.fromMap(Map<String, Object?> map) => InvoiceSummary(
        id: map['id'] as int,
        invoiceNumber: map['invoice_number'] as String,
        customerId: map['customer_id'] as int?,
        customerName: map['customer_name'] as String?,
        totalPaise: map['total'] as int,
        status: map['status'] as String,
        createdAt: map['created_at'] as int,
        paymentMethods: (map['payment_methods'] as String?)
                ?.split(',')
                .where((e) => e.isNotEmpty)
                .toList() ??
            const [],
      );
}

class InvoiceDetail {
  const InvoiceDetail({
    required this.summary,
    required this.subtotalPaise,
    required this.discountPaise,
    required this.taxPaise,
    this.note,
    this.originalInvoiceId,
    required this.items,
    required this.payments,
  });

  final InvoiceSummary summary;
  final int subtotalPaise;
  final int discountPaise;
  final int taxPaise;
  final String? note;
  final int? originalInvoiceId;
  final List<InvoiceLine> items;
  final List<PaymentRecord> payments;
}

class InvoiceLine {
  const InvoiceLine({
    required this.id,
    required this.productId,
    required this.name,
    this.barcode,
    required this.quantity,
    required this.unitPricePaise,
    required this.discountPaise,
    required this.taxPaise,
    required this.totalPaise,
  });

  final int id;
  final int? productId;
  final String name;
  final String? barcode;
  final int quantity;
  final int unitPricePaise;
  final int discountPaise;
  final int taxPaise;
  final int totalPaise;

  factory InvoiceLine.fromMap(Map<String, Object?> map) => InvoiceLine(
        id: map['id'] as int,
        productId: map['product_id'] as int?,
        name: map['product_name_snapshot'] as String,
        barcode: map['barcode_snapshot'] as String?,
        quantity: map['quantity'] as int,
        unitPricePaise: map['unit_price'] as int,
        discountPaise: map['discount'] as int,
        taxPaise: map['tax'] as int,
        totalPaise: map['total'] as int,
      );
}

class PaymentRecord {
  const PaymentRecord({
    required this.id,
    required this.invoiceId,
    required this.method,
    required this.amountPaise,
    this.receivedPaise,
    this.changePaise,
    required this.createdAt,
  });

  final int id;
  final int invoiceId;
  final String method;
  final int amountPaise;
  final int? receivedPaise;
  final int? changePaise;
  final int createdAt;

  factory PaymentRecord.fromMap(Map<String, Object?> map) => PaymentRecord(
        id: map['id'] as int,
        invoiceId: map['invoice_id'] as int,
        method: map['payment_method'] as String,
        amountPaise: map['amount'] as int,
        receivedPaise: map['received_amount'] as int?,
        changePaise: map['change_amount'] as int?,
        createdAt: map['created_at'] as int,
      );
}

enum StockHistoryFilter { all, stockIn, stockOut }

class StockMovement {
  const StockMovement({
    required this.id,
    required this.productId,
    this.productName,
    this.productSku,
    this.productUnit = 'pcs',
    this.sellingPricePaise = 0,
    required this.type,
    required this.quantity,
    this.unitCostPaise,
    this.referenceType,
    this.referenceId,
    this.referenceLabel,
    this.note,
    required this.createdAt,
  });

  final int id;
  final int productId;
  final String? productName;
  final String? productSku;
  final String productUnit;
  final int sellingPricePaise;
  final String type;
  final int quantity;
  final int? unitCostPaise;
  final String? referenceType;
  final int? referenceId;
  final String? referenceLabel;
  final String? note;
  final int createdAt;

  bool get isIn => quantity > 0;
  bool get isOut => quantity < 0;

  factory StockMovement.fromMap(Map<String, Object?> map) => StockMovement(
        id: map['id'] as int,
        productId: map['product_id'] as int,
        productName: map['product_name'] as String?,
        productSku: map['product_sku'] as String?,
        productUnit: (map['product_unit'] as String?) ?? 'pcs',
        sellingPricePaise: (map['selling_price'] as int?) ?? 0,
        type: map['transaction_type'] as String,
        quantity: map['quantity'] as int,
        unitCostPaise: map['unit_cost'] as int?,
        referenceType: map['reference_type'] as String?,
        referenceId: map['reference_id'] as int?,
        referenceLabel: map['reference_label'] as String?,
        note: map['note'] as String?,
        createdAt: map['created_at'] as int,
      );
}

class Expense {
  const Expense({
    required this.id,
    required this.storeId,
    required this.category,
    required this.amountPaise,
    required this.paymentMethod,
    this.note,
    required this.spentAt,
    required this.createdAt,
  });

  final int id;
  final int storeId;
  final String category;
  final int amountPaise;
  final String paymentMethod;
  final String? note;
  final int spentAt;
  final int createdAt;

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
        id: map['id'] as int,
        storeId: map['store_id'] as int,
        category: map['category'] as String,
        amountPaise: map['amount'] as int,
        paymentMethod: map['payment_method'] as String,
        note: map['note'] as String?,
        spentAt: map['spent_at'] as int,
        createdAt: map['created_at'] as int,
      );
}

class BackupRecord {
  const BackupRecord({
    required this.id,
    required this.fileName,
    this.driveFileId,
    this.localPath,
    required this.backupVersion,
    required this.databaseVersion,
    this.fileSize,
    this.checksum,
    required this.status,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
  });

  final int id;
  final String fileName;
  final String? driveFileId;
  final String? localPath;
  final int backupVersion;
  final int databaseVersion;
  final int? fileSize;
  final String? checksum;
  final String status;
  final int createdAt;
  final int? completedAt;
  final String? errorMessage;

  factory BackupRecord.fromMap(Map<String, Object?> map) => BackupRecord(
        id: map['id'] as int,
        fileName: map['file_name'] as String,
        driveFileId: map['drive_file_id'] as String?,
        localPath: map['local_path'] as String?,
        backupVersion: map['backup_version'] as int,
        databaseVersion: map['database_version'] as int,
        fileSize: map['file_size'] as int?,
        checksum: map['checksum'] as String?,
        status: map['status'] as String,
        createdAt: map['created_at'] as int,
        completedAt: map['completed_at'] as int?,
        errorMessage: map['error_message'] as String?,
      );
}

class SavedPrinter {
  const SavedPrinter({
    required this.id,
    required this.name,
    required this.connectionType,
    this.address,
    this.paperSize = '58mm',
    this.isDefault = false,
  });

  final int id;
  final String name;
  final String connectionType;
  final String? address;
  final String paperSize;
  final bool isDefault;

  factory SavedPrinter.fromMap(Map<String, Object?> map) => SavedPrinter(
        id: map['id'] as int,
        name: map['name'] as String,
        connectionType: map['connection_type'] as String,
        address: map['address'] as String?,
        paperSize: (map['paper_size'] as String?) ?? '58mm',
        isDefault: intToBool(map['is_default']),
      );
}

class DashboardStats {
  const DashboardStats({
    required this.todaySalesPaise,
    required this.billsToday,
    required this.itemsInStock,
    required this.lowStockCount,
  });

  final int todaySalesPaise;
  final int billsToday;
  final int itemsInStock;
  final int lowStockCount;
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/customer_repository.dart';
import 'package:pos_billing/core/database/repositories/expense_repository.dart';
import 'package:pos_billing/core/database/repositories/product_repository.dart';
import 'package:pos_billing/core/database/repositories/sales_repository.dart';
import 'package:pos_billing/core/database/repositories/settings_repository.dart';
import 'package:pos_billing/core/database/repositories/stock_repository.dart';
import 'package:pos_billing/core/database/repositories/store_repository.dart';
import 'package:pos_billing/core/money/billing_calculation_service.dart';
import 'package:pos_billing/core/security/pin_service.dart';
import 'package:pos_billing/core/services/backup_service.dart';
import 'package:pos_billing/core/services/bluetooth_printer_service.dart';
import 'package:pos_billing/core/services/connectivity_service.dart';
import 'package:pos_billing/core/services/google_drive_client.dart';
import 'package:pos_billing/core/services/printer_service.dart';
import 'package:pos_billing/core/services/receipt_builder.dart';
import 'package:pos_billing/shared/models/models.dart';
import 'package:pos_billing/shared/models/store_profile.dart';

final databaseHolderProvider = StateProvider<AppDatabase?>((ref) => null);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = ref.watch(databaseHolderProvider);
  if (db == null) {
    throw StateError('Database not initialized');
  }
  return db;
});

final settingsRepositoryProvider = Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final storeRepositoryProvider = Provider((ref) => StoreRepository(ref.watch(databaseProvider)));
final productRepositoryProvider = Provider((ref) => ProductRepository(ref.watch(databaseProvider)));
final stockRepositoryProvider = Provider((ref) => StockRepository(ref.watch(databaseProvider)));
final customerRepositoryProvider = Provider((ref) => CustomerRepository(ref.watch(databaseProvider)));
final salesRepositoryProvider = Provider(
  (ref) => SalesRepository(ref.watch(databaseProvider), calculator: ref.watch(billingCalcProvider)),
);
final expenseRepositoryProvider = Provider((ref) => ExpenseRepository(ref.watch(databaseProvider)));
final billingCalcProvider = Provider((ref) => const BillingCalculationService());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final pinServiceProvider = Provider((ref) => PinService(ref.watch(secureStorageProvider)));
final driveClientProvider = Provider<DriveBackupClient>((ref) => GoogleDriveBackupClient());
final backupServiceProvider = Provider(
  (ref) => BackupService(
    ref.watch(databaseProvider),
    secureStorage: ref.watch(secureStorageProvider),
    drive: ref.watch(driveClientProvider),
  ),
);
final printerServiceProvider = Provider<PrinterService>((ref) {
  return CompositePrinterService(
    bluetooth: BluetoothPrinterService(),
    usb: UnsupportedPrinterService('USB'),
    network: UnsupportedPrinterService('Network'),
  );
});
final receiptBuilderProvider = Provider((ref) => ReceiptBuilder());
final connectivityServiceProvider = Provider((ref) => ConnectivityService());
final isOnlineProvider = StreamProvider<bool>((ref) => ref.watch(connectivityServiceProvider).onlineStream);

class AppSettings {
  const AppSettings({
    required this.localeCode,
    required this.themeModeName,
    required this.accent,
    required this.onboardingComplete,
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.allowNegativeStock,
    required this.autoBackup,
    required this.paperSize,
  });

  final String localeCode;
  final String themeModeName;
  final String accent;
  final bool onboardingComplete;
  final bool pinEnabled;
  final bool biometricEnabled;
  final bool allowNegativeStock;
  final String autoBackup;
  final String paperSize;

  factory AppSettings.defaults() => const AppSettings(
        localeCode: 'en',
        themeModeName: 'system',
        accent: 'teal',
        onboardingComplete: false,
        pinEnabled: false,
        biometricEnabled: false,
        allowNegativeStock: false,
        autoBackup: 'off',
        paperSize: '58mm',
      );
}

final appSettingsProvider = AsyncNotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

class AppSettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => _load();

  Future<AppSettings> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    return AppSettings(
      localeCode: await repo.get(SettingKeys.localeCode) ?? 'en',
      themeModeName: await repo.get(SettingKeys.themeMode) ?? 'system',
      accent: await repo.get(SettingKeys.accentColor) ?? 'teal',
      onboardingComplete: await repo.getBool(SettingKeys.onboardingComplete),
      pinEnabled: await repo.getBool(SettingKeys.pinEnabled),
      biometricEnabled: await repo.getBool(SettingKeys.biometricEnabled),
      allowNegativeStock: await repo.getBool(SettingKeys.allowNegativeStock),
      autoBackup: await repo.get(SettingKeys.autoBackup) ?? 'off',
      paperSize: await repo.get(SettingKeys.paperSize) ?? '58mm',
    );
  }

  Future<void> _patch(Future<void> Function(SettingsRepository repo) fn) async {
    await fn(ref.read(settingsRepositoryProvider));
    state = AsyncData(await _load());
  }

  Future<void> setLocale(String code) => _patch((r) => r.set(SettingKeys.localeCode, code));
  Future<void> setThemeMode(String mode) => _patch((r) => r.set(SettingKeys.themeMode, mode));
  Future<void> setAccent(String accent) => _patch((r) => r.set(SettingKeys.accentColor, accent));
  Future<void> completeOnboarding() => _patch((r) => r.setBool(SettingKeys.onboardingComplete, true));
  Future<void> setPinEnabled(bool value) => _patch((r) => r.setBool(SettingKeys.pinEnabled, value));
  Future<void> setBiometricEnabled(bool value) => _patch((r) => r.setBool(SettingKeys.biometricEnabled, value));
  Future<void> setAllowNegativeStock(bool value) =>
      _patch((r) => r.setBool(SettingKeys.allowNegativeStock, value));
  Future<void> setAutoBackup(String value) => _patch((r) => r.set(SettingKeys.autoBackup, value));
  Future<void> setPaperSize(String value) => _patch((r) => r.set(SettingKeys.paperSize, value));
}

final storeProfileProvider = AsyncNotifierProvider<StoreController, StoreProfile?>(StoreController.new);

class StoreController extends AsyncNotifier<StoreProfile?> {
  @override
  Future<StoreProfile?> build() => ref.read(storeRepositoryProvider).loadStore();

  Future<StoreProfile> save(StoreProfile profile, {bool complete = false}) async {
    final repo = ref.read(storeRepositoryProvider);
    final existing = state.valueOrNull;
    final StoreProfile saved;
    if (existing == null) {
      saved = await repo.createStore(profile);
    } else {
      saved = await repo.updateStore(
        profile.copyWith(isSetupCompleted: complete || existing.isSetupCompleted),
      );
    }
    if (complete) {
      await repo.completeSetup(saved);
    }
    state = AsyncData(await repo.loadStore());
    return state.value!;
  }

  Future<void> reload() async {
    state = AsyncData(await ref.read(storeRepositoryProvider).loadStore());
  }
}

final unlockedProvider = StateProvider<bool>((ref) => false);

class CatalogQuery {
  const CatalogQuery({
    this.search = '',
    this.categoryId,
    this.lowStock = false,
    this.outOfStock = false,
    this.inactiveOnly = false,
  });

  final String search;
  final int? categoryId;
  final bool lowStock;
  final bool outOfStock;
  final bool inactiveOnly;

  CatalogQuery copyWith({
    String? search,
    int? categoryId,
    bool? lowStock,
    bool? outOfStock,
    bool? inactiveOnly,
    bool clearCategory = false,
  }) {
    return CatalogQuery(
      search: search ?? this.search,
      categoryId: clearCategory ? null : categoryId ?? this.categoryId,
      lowStock: lowStock ?? this.lowStock,
      outOfStock: outOfStock ?? this.outOfStock,
      inactiveOnly: inactiveOnly ?? this.inactiveOnly,
    );
  }
}

final catalogQueryProvider = StateProvider<CatalogQuery>((ref) => const CatalogQuery());

final productsProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return const [];
  final query = ref.watch(catalogQueryProvider);
  return ref.watch(productRepositoryProvider).getProducts(
        store.id,
        ProductQuery(
          search: query.search,
          categoryId: query.categoryId,
          lowStockOnly: query.lowStock,
          outOfStockOnly: query.outOfStock,
          activeOnly: !query.inactiveOnly,
          inactiveOnly: query.inactiveOnly,
        ),
      );
});

final categoriesProvider = FutureProvider.autoDispose<List<Category>>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return const [];
  return ref.watch(productRepositoryProvider).getCategories(store.id);
});

final stockHistoryFilterProvider =
    StateProvider<StockHistoryFilter>((ref) => StockHistoryFilter.all);

final stockHistorySearchProvider = StateProvider<String>((ref) => '');

final stockHistoryProvider =
    FutureProvider.autoDispose<List<StockMovement>>((ref) async {
  final filter = ref.watch(stockHistoryFilterProvider);
  final query = ref.watch(stockHistorySearchProvider);
  return ref.watch(stockRepositoryProvider).history(
        filter: filter,
        query: query,
      );
});

class CartState {
  const CartState({
    this.lines = const [],
    this.billDiscountPaise = 0,
    this.taxOverridePaise,
    this.customer,
  });

  final List<CartLine> lines;
  final int billDiscountPaise;
  /// When set, replaces product-rate tax for this bill.
  final int? taxOverridePaise;
  final Customer? customer;

  CartState copyWith({
    List<CartLine>? lines,
    int? billDiscountPaise,
    int? taxOverridePaise,
    Customer? customer,
    bool clearCustomer = false,
    bool clearTaxOverride = false,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      billDiscountPaise: billDiscountPaise ?? this.billDiscountPaise,
      taxOverridePaise:
          clearTaxOverride ? null : taxOverridePaise ?? this.taxOverridePaise,
      customer: clearCustomer ? null : customer ?? this.customer,
    );
  }
}

final cartProvider = NotifierProvider<CartController, CartState>(CartController.new);

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void addProduct(Product product, {String? barcode}) {
    final index = state.lines.indexWhere((l) => l.product.id == product.id);
    if (index >= 0) {
      final updated = [...state.lines];
      updated[index] = updated[index].copyWith(quantity: updated[index].quantity + 1);
      state = state.copyWith(lines: updated);
    } else {
      state = state.copyWith(
        lines: [...state.lines, CartLine(product: product, quantity: 1, barcode: barcode)],
      );
    }
  }

  void setQty(int productId, int qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.product.id == productId) line.copyWith(quantity: qty) else line,
      ],
    );
  }

  void setItemDiscount(int productId, int paise) {
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.product.id == productId) line.copyWith(itemDiscountPaise: paise) else line,
      ],
    );
  }

  void remove(int productId) {
    state = state.copyWith(lines: state.lines.where((l) => l.product.id != productId).toList());
  }

  void clear() => state = const CartState();

  void setBillDiscount(int paise) => state = state.copyWith(billDiscountPaise: paise);

  void setTaxOverride(int? paise) {
    if (paise == null) {
      state = state.copyWith(clearTaxOverride: true);
    } else {
      state = state.copyWith(taxOverridePaise: paise < 0 ? 0 : paise);
    }
  }

  void setCustomer(Customer? customer) =>
      state = state.copyWith(customer: customer, clearCustomer: customer == null);
}

final cartTotalsProvider = Provider((ref) {
  final cart = ref.watch(cartProvider);
  final calc = ref.watch(billingCalcProvider);
  final result = calc.calculate(
    lines: [
      for (final line in cart.lines)
        LineCalcInput(
          unitPricePaise: line.product.sellingPricePaise,
          quantity: line.quantity,
          itemDiscountPaise: line.itemDiscountPaise,
          taxRateBp: line.product.taxRateBp,
        ),
    ],
    billDiscountPaise: cart.billDiscountPaise,
  );
  final override = cart.taxOverridePaise;
  if (override == null) return result;
  return calc.applyTaxOverride(result, override);
});

final dashboardStatsProvider = FutureProvider.autoDispose<DashboardStats?>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return null;
  return ref.watch(salesRepositoryProvider).dashboardStats(store.id);
});

final salesRangeProvider = StateProvider<SalesDateRange>((ref) => SalesDateRange.today());
final salesPaymentFilterProvider = StateProvider<String?>((ref) => null);

final salesListProvider = FutureProvider.autoDispose<List<InvoiceSummary>>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return const [];
  return ref.watch(salesRepositoryProvider).listSales(
        storeId: store.id,
        range: ref.watch(salesRangeProvider),
        paymentMethod: ref.watch(salesPaymentFilterProvider),
      );
});

enum ScanPurpose { addToCart, lookup, stockIn, captureBarcode }

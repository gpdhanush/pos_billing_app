import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_billing/core/analytics/analytics_service.dart';
import 'package:pos_billing/core/auth/google_auth_service.dart';
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
import 'package:pos_billing/core/notifications/notification_service.dart';
import 'package:pos_billing/core/security/pin_service.dart';
import 'package:pos_billing/core/services/backup_coordinator.dart';
import 'package:pos_billing/core/services/backup_background.dart';
import 'package:pos_billing/core/services/backup_crypto.dart';
import 'package:pos_billing/core/services/backup_dirty_tracker.dart';
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

final settingsRepositoryProvider =
    Provider((ref) => SettingsRepository(ref.watch(databaseProvider)));
final storeRepositoryProvider =
    Provider((ref) => StoreRepository(ref.watch(databaseProvider)));
final productRepositoryProvider =
    Provider((ref) => ProductRepository(ref.watch(databaseProvider)));
final stockRepositoryProvider =
    Provider((ref) => StockRepository(ref.watch(databaseProvider)));
final customerRepositoryProvider =
    Provider((ref) => CustomerRepository(ref.watch(databaseProvider)));
final salesRepositoryProvider = Provider(
  (ref) => SalesRepository(
    ref.watch(databaseProvider),
    calculator: ref.watch(billingCalcProvider),
  ),
);
final expenseRepositoryProvider =
    Provider((ref) => ExpenseRepository(ref.watch(databaseProvider)));
final billingCalcProvider = Provider((ref) => const BillingCalculationService());
final secureStorageProvider = Provider((ref) => const FlutterSecureStorage());
final pinServiceProvider =
    Provider((ref) => PinService(ref.watch(secureStorageProvider)));

final googleAuthServiceProvider = Provider(
  (ref) => GoogleAuthService(secureStorage: ref.watch(secureStorageProvider)),
);

final googleSessionProvider =
    FutureProvider<GoogleAccountSession?>((ref) async {
  final auth = ref.watch(googleAuthServiceProvider);
  // Prefer a live Google session (Drive-ready). Fall back to cached profile
  // for display only when silent restore cannot refresh tokens yet.
  return auth.restoreSilently(allowCachedProfile: true);
});

final driveClientProvider = Provider<DriveBackupClient>(
  (ref) => GoogleDriveBackupClient(auth: ref.watch(googleAuthServiceProvider)),
);

final backupCryptoProvider = Provider(
  (ref) => BackupCrypto(ref.watch(secureStorageProvider)),
);

final backupDirtyTrackerProvider = Provider(
  (ref) => BackupDirtyTracker(ref.watch(settingsRepositoryProvider)),
);

final backupServiceProvider = Provider(
  (ref) => BackupService(
    ref.watch(databaseProvider),
    secureStorage: ref.watch(secureStorageProvider),
    drive: ref.watch(driveClientProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    crypto: ref.watch(backupCryptoProvider),
  ),
);

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService(
    connectivity: ref.watch(connectivityServiceProvider),
    notifications: ref.watch(notificationServiceProvider),
  );
});

final backupCoordinatorProvider = Provider<BackupCoordinator>((ref) {
  final coordinator = BackupCoordinator(
    backupService: ref.watch(backupServiceProvider),
    settings: ref.watch(settingsRepositoryProvider),
    connectivity: ref.watch(connectivityServiceProvider),
    dirtyTracker: ref.watch(backupDirtyTrackerProvider),
    notifications: ref.watch(notificationServiceProvider),
    analytics: ref.watch(analyticsServiceProvider),
  );
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final printerServiceProvider = Provider<PrinterService>((ref) {
  return CompositePrinterService(
    bluetooth: BluetoothPrinterService(),
    usb: UnsupportedPrinterService('USB'),
    network: UnsupportedPrinterService('Network'),
  );
});
final receiptBuilderProvider = Provider((ref) => ReceiptBuilder());
final connectivityServiceProvider = Provider((ref) => ConnectivityService());
final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(connectivityServiceProvider).onlineStream,
);

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
    required this.backupWifiOnly,
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
  final bool backupWifiOnly;

  factory AppSettings.defaults() => const AppSettings(
        localeCode: 'en',
        themeModeName: 'light',
        accent: 'teal',
        onboardingComplete: false,
        pinEnabled: false,
        biometricEnabled: false,
        allowNegativeStock: false,
        autoBackup: 'daily',
        paperSize: '58mm',
        backupWifiOnly: true,
      );
}

final appSettingsProvider =
    AsyncNotifierProvider<AppSettingsController, AppSettings>(
  AppSettingsController.new,
);

class AppSettingsController extends AsyncNotifier<AppSettings> {
  @override
  Future<AppSettings> build() => _load();

  Future<AppSettings> _load() async {
    final repo = ref.read(settingsRepositoryProvider);
    // Existing installs without the key keep previous 'off' behavior.
    final autoBackupRaw = await repo.get(SettingKeys.autoBackup);
    return AppSettings(
      localeCode: await repo.get(SettingKeys.localeCode) ?? 'en',
      themeModeName: await repo.get(SettingKeys.themeMode) ?? 'light',
      accent: await repo.get(SettingKeys.accentColor) ?? 'teal',
      onboardingComplete: await repo.getBool(SettingKeys.onboardingComplete),
      pinEnabled: await repo.getBool(SettingKeys.pinEnabled),
      biometricEnabled: await repo.getBool(SettingKeys.biometricEnabled),
      allowNegativeStock: await repo.getBool(SettingKeys.allowNegativeStock),
      autoBackup: autoBackupRaw ?? 'off',
      paperSize: await repo.get(SettingKeys.paperSize) ?? '58mm',
      backupWifiOnly:
          await repo.getBool(SettingKeys.backupWifiOnly, fallback: true),
    );
  }

  Future<void> _patch(Future<void> Function(SettingsRepository repo) fn) async {
    await fn(ref.read(settingsRepositoryProvider));
    state = AsyncData(await _load());
  }

  Future<void> setLocale(String code) =>
      _patch((r) => r.set(SettingKeys.localeCode, code));
  Future<void> setThemeMode(String mode) =>
      _patch((r) => r.set(SettingKeys.themeMode, mode));
  Future<void> setAccent(String accent) =>
      _patch((r) => r.set(SettingKeys.accentColor, accent));
  Future<void> completeOnboarding() => _patch((r) async {
        await r.setBool(SettingKeys.onboardingComplete, true);
        // New installs only: seed daily auto-backup when unset.
        if (await r.get(SettingKeys.autoBackup) == null) {
          await r.set(SettingKeys.autoBackup, 'daily');
        }
        if (await r.get(SettingKeys.backupWifiOnly) == null) {
          await r.setBool(SettingKeys.backupWifiOnly, true);
        }
        await BackupBackgroundScheduler.syncFromSettings(r);
      });
  Future<void> setPinEnabled(bool value) =>
      _patch((r) => r.setBool(SettingKeys.pinEnabled, value));
  Future<void> setBiometricEnabled(bool value) =>
      _patch((r) => r.setBool(SettingKeys.biometricEnabled, value));
  Future<void> setAllowNegativeStock(bool value) =>
      _patch((r) => r.setBool(SettingKeys.allowNegativeStock, value));
  Future<void> setAutoBackup(String value) => _patch((r) async {
        await r.set(SettingKeys.autoBackup, value);
        await BackupBackgroundScheduler.syncFromSettings(r);
      });
  Future<void> setPaperSize(String value) =>
      _patch((r) => r.set(SettingKeys.paperSize, value));
  Future<void> setBackupWifiOnly(bool value) => _patch((r) async {
        await r.setBool(SettingKeys.backupWifiOnly, value);
        await BackupBackgroundScheduler.syncFromSettings(r);
      });

  Future<String?> readRaw(String key) =>
      ref.read(settingsRepositoryProvider).get(key);

  Future<void> writeRaw(String key, String value) =>
      ref.read(settingsRepositoryProvider).set(key, value);
}

final storeProfileProvider =
    AsyncNotifierProvider<StoreController, StoreProfile?>(StoreController.new);

class StoreController extends AsyncNotifier<StoreProfile?> {
  @override
  Future<StoreProfile?> build() =>
      ref.read(storeRepositoryProvider).loadStore();

  Future<StoreProfile> save(StoreProfile profile, {bool complete = false}) async {
    final repo = ref.read(storeRepositoryProvider);
    final existing = state.valueOrNull;
    final StoreProfile saved;
    if (existing == null) {
      saved = await repo.createStore(profile);
    } else {
      saved = await repo.updateStore(
        profile.copyWith(
          isSetupCompleted: complete || existing.isSetupCompleted,
        ),
      );
    }
    if (complete) {
      await repo.completeSetup(saved);
      await ref.read(analyticsServiceProvider).logEvent('store_setup_completed');
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

final catalogQueryProvider =
    StateProvider<CatalogQuery>((ref) => const CatalogQuery());

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

class ProductFilterCounts {
  const ProductFilterCounts({
    required this.all,
    required this.lowStock,
    required this.outOfStock,
    required this.inactive,
  });

  final int all;
  final int lowStock;
  final int outOfStock;
  final int inactive;
}

final productFilterCountsProvider =
    FutureProvider.autoDispose<ProductFilterCounts>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) {
    return const ProductFilterCounts(
      all: 0,
      lowStock: 0,
      outOfStock: 0,
      inactive: 0,
    );
  }
  final search = ref.watch(catalogQueryProvider).search;
  final items = await ref.watch(productRepositoryProvider).getProducts(
        store.id,
        ProductQuery(
          search: search,
          activeOnly: false,
          inactiveOnly: false,
          limit: 5000,
        ),
      );
  final active = items.where((p) => p.isActive).toList();
  return ProductFilterCounts(
    all: active.length,
    lowStock: active.where((p) => p.isLowStock && !p.isOutOfStock).length,
    outOfStock: active.where((p) => p.isOutOfStock).length,
    inactive: items.where((p) => !p.isActive).length,
  );
});

/// Active products for the Inventory tab (independent of Products filters).
final inventoryProductsProvider =
    FutureProvider.autoDispose<List<Product>>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return const [];
  return ref.watch(productRepositoryProvider).getProducts(
        store.id,
        const ProductQuery(activeOnly: true, limit: 5000),
      );
});

final categoriesProvider =
    FutureProvider.autoDispose<List<Category>>((ref) async {
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
  final int? taxOverridePaise;
  final Customer? customer;

  bool get hasUnsavedValues =>
      lines.isNotEmpty ||
      customer != null ||
      billDiscountPaise > 0 ||
      taxOverridePaise != null;

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

final cartProvider =
    NotifierProvider<CartController, CartState>(CartController.new);

class CartController extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  /// Returns `false` when stock is insufficient and negative stock is disabled.
  bool addProduct(Product product, {String? barcode}) {
    final allowNegative =
        ref.read(appSettingsProvider).valueOrNull?.allowNegativeStock ?? false;
    final index = state.lines.indexWhere((l) => l.product.id == product.id);
    final nextQty = index >= 0 ? state.lines[index].quantity + 1 : 1;
    if (!allowNegative && nextQty > product.currentStock) {
      return false;
    }
    if (index >= 0) {
      final updated = [...state.lines];
      updated[index] = updated[index].copyWith(quantity: nextQty);
      state = state.copyWith(lines: updated);
    } else {
      state = state.copyWith(
        lines: [
          ...state.lines,
          CartLine(product: product, quantity: 1, barcode: barcode),
        ],
      );
    }
    return true;
  }

  void setQty(int productId, int qty) {
    if (qty <= 0) {
      remove(productId);
      return;
    }
    final allowNegative =
        ref.read(appSettingsProvider).valueOrNull?.allowNegativeStock ?? false;
    final existing =
        state.lines.where((l) => l.product.id == productId).firstOrNull;
    if (existing != null &&
        !allowNegative &&
        qty > existing.product.currentStock) {
      return;
    }
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.product.id == productId)
            line.copyWith(quantity: qty)
          else
            line,
      ],
    );
  }

  void setItemDiscount(int productId, int paise) {
    state = state.copyWith(
      lines: [
        for (final line in state.lines)
          if (line.product.id == productId)
            line.copyWith(itemDiscountPaise: paise)
          else
            line,
      ],
    );
  }

  void remove(int productId) {
    state = state.copyWith(
      lines: state.lines.where((l) => l.product.id != productId).toList(),
    );
  }

  void clear() => state = const CartState();

  void setBillDiscount(int paise) =>
      state = state.copyWith(billDiscountPaise: paise);

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

final dashboardStatsProvider =
    FutureProvider.autoDispose<DashboardStats?>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return null;
  return ref.watch(salesRepositoryProvider).dashboardStats(store.id);
});

final salesRangeProvider =
    StateProvider<SalesDateRange>((ref) => SalesDateRange.today());
final salesPaymentFilterProvider = StateProvider<String?>((ref) => null);

final salesListProvider =
    FutureProvider.autoDispose<List<InvoiceSummary>>((ref) async {
  final store = await ref.watch(storeProfileProvider.future);
  if (store == null) return const [];
  return ref.watch(salesRepositoryProvider).listSales(
        storeId: store.id,
        range: ref.watch(salesRangeProvider),
        paymentMethod: ref.watch(salesPaymentFilterProvider),
      );
});

enum ScanPurpose { addToCart, lookup, stockIn, captureBarcode }

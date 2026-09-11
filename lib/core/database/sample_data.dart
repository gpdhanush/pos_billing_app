import 'package:flutter/foundation.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/product_repository.dart';
import 'package:pos_billing/core/database/repositories/settings_repository.dart';

class SampleDataSeeder {
  SampleDataSeeder(this._db);

  final AppDatabase _db;

  Future<void> seedIfNeeded(int storeId) async {
    if (!kDebugMode) return;
    final settings = SettingsRepository(_db);
    if (await settings.getBool(SettingKeys.sampleDataLoaded)) return;
    final products = ProductRepository(_db);
    final existing = await products.getProducts(storeId, const ProductQuery(limit: 1));
    if (existing.isNotEmpty) {
      await settings.setBool(SettingKeys.sampleDataLoaded, true);
      return;
    }
    final categories = await products.getCategories(storeId);
    final catId = categories.isEmpty ? null : categories.first.id;
    const items = [
      ('Rice 5kg', '890100000001', 42000, 48000, 5, 20),
      ('Milk 1L', '890100000002', 4500, 5600, 8, 30),
      ('Sugar 1kg', '890100000003', 3800, 4500, 6, 25),
      ('Cooking Oil 1L', '890100000004', 12000, 14500, 4, 15),
      ('Biscuits', '890100000005', 2000, 3000, 10, 40),
      ('Soap', '890100000006', 2500, 3500, 12, 25),
      ('Shampoo', '890100000007', 8000, 11000, 6, 12),
    ];
    for (final item in items) {
      await products.createProduct(
        ProductDraft(
          storeId: storeId,
          name: item.$1,
          sku: item.$2,
          categoryId: catId,
          sellingPricePaise: item.$4,
          purchasePricePaise: item.$3,
          taxRateBp: 1800,
          minimumStock: item.$5,
          openingStock: item.$6,
          barcodes: [item.$2],
        ),
      );
    }
    await settings.setBool(SettingKeys.sampleDataLoaded, true);
  }
}

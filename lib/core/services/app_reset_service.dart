import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/services/backup_background.dart';
import 'package:pos_billing/core/services/backup_service.dart';
import 'package:workmanager/workmanager.dart';

/// Full local wipe used by Settings → Log out.
///
/// Deletes the SQLite database (all shop records), secure keys, local media,
/// and local backup packages, then reopens an empty database.
class AppResetService {
  AppResetService(this._ref);

  final Ref _ref;

  Future<void> wipeAllLocalData() async {
    final current = _ref.read(databaseProvider);
    final storage = _ref.read(secureStorageProvider);
    final drive = _ref.read(driveClientProvider);

    try {
      if (await drive.isSignedIn) {
        await drive.signOut();
      }
    } catch (_) {
      // Continue wipe even if Drive sign-out fails.
    }

    try {
      await Workmanager().cancelByUniqueName(kAutoBackupTaskUniqueName);
    } catch (_) {}

    await _deleteDir('product_images');
    await _deleteDir('store_logos');
    await _deleteDir('backups');
    await _deleteDir(p.join('POS Billing', 'backup'));
    await BackupService.wipeLocalBackupFolders();

    await storage.deleteAll();

    final fresh = await AppDatabase.wipeAndReopen(current);
    _ref.read(databaseHolderProvider.notifier).state = fresh;

    _ref.read(cartProvider.notifier).clear();
    _ref.read(catalogQueryProvider.notifier).state = const CatalogQuery();
    _ref.read(unlockedProvider.notifier).state = true;

    // Invalidate only — do not await providers here. Awaiting appSettings
    // refreshes GoRouter and redirects away from Settings while a loading
    // dialog is still open, which crashes Navigator.pop.
    _ref.invalidate(appSettingsProvider);
    _ref.invalidate(storeProfileProvider);
    _ref.invalidate(productsProvider);
    _ref.invalidate(categoriesProvider);
    _ref.invalidate(salesListProvider);
    _ref.invalidate(dashboardStatsProvider);
    _ref.invalidate(backupServiceProvider);
    _ref.invalidate(googleSessionProvider);
  }

  Future<void> _deleteDir(String name) async {
    try {
      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory(p.join(docs.path, name));
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    } catch (_) {
      // Best-effort cleanup.
    }
  }
}

final appResetServiceProvider = Provider<AppResetService>(
  (ref) => AppResetService(ref),
);

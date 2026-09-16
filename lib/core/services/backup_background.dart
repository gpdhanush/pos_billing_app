import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:pos_billing/core/analytics/analytics_service.dart';
import 'package:pos_billing/core/auth/google_auth_service.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/database/repositories/settings_repository.dart';
import 'package:pos_billing/core/notifications/notification_service.dart';
import 'package:pos_billing/core/services/backup_coordinator.dart';
import 'package:pos_billing/core/services/backup_crypto.dart';
import 'package:pos_billing/core/services/backup_dirty_tracker.dart';
import 'package:pos_billing/core/services/backup_service.dart';
import 'package:pos_billing/core/services/connectivity_service.dart';
import 'package:pos_billing/core/services/google_drive_client.dart';
import 'package:workmanager/workmanager.dart';

/// Android WorkManager unique name for periodic auto-backup.
const kAutoBackupTaskUniqueName = 'pos_auto_backup';

/// Task name delivered to [backupCallbackDispatcher].
const kAutoBackupTaskName = 'pos_auto_backup';

/// Top-level entry point invoked by WorkManager when the app is closed.
@pragma('vm:entry-point')
void backupCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      await runBackgroundAutoBackup();
      return true;
    } catch (_) {
      // Retry later — do not crash the worker isolate.
      return false;
    }
  });
}

/// Builds services in a fresh isolate and runs the same auto-backup gate
/// used when the app is open.
Future<void> runBackgroundAutoBackup() async {
  final storage = const FlutterSecureStorage();
  final db = await AppDatabase.open();
  try {
    final settings = SettingsRepository(db);
    final auth = GoogleAuthService(secureStorage: storage);
    await auth.restoreSilently();
    final drive = GoogleDriveBackupClient(auth: auth);
    final connectivity = ConnectivityService();
    final crypto = BackupCrypto(storage);
    final notifications = NotificationService();
    await notifications.init(firebaseAvailable: false);
    final analytics = AnalyticsService(
      connectivity: connectivity,
      notifications: notifications,
    );
    final backup = BackupService(
      db,
      secureStorage: storage,
      drive: drive,
      connectivity: connectivity,
      crypto: crypto,
    );
    final coordinator = BackupCoordinator(
      backupService: backup,
      settings: settings,
      connectivity: connectivity,
      dirtyTracker: BackupDirtyTracker(settings),
      notifications: notifications,
      analytics: analytics,
    );
    await coordinator.maybeRunAutoBackup();
  } finally {
    await db.close();
  }
}

/// Registers / cancels the OS periodic worker from current settings.
class BackupBackgroundScheduler {
  BackupBackgroundScheduler._();

  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) return;
    await Workmanager().initialize(backupCallbackDispatcher);
    _initialized = true;
  }

  /// Call after auto-backup frequency or Wi‑Fi-only preference changes.
  static Future<void> syncFromSettings(SettingsRepository settings) async {
    await initialize();
    final freq = await settings.get(SettingKeys.autoBackup) ?? 'off';
    if (freq == 'off' || freq.isEmpty) {
      await Workmanager().cancelByUniqueName(kAutoBackupTaskUniqueName);
      return;
    }

    final wifiOnly =
        await settings.getBool(SettingKeys.backupWifiOnly, fallback: true);

    // Fire roughly twice a day; [BackupCoordinator] decides if a backup is due.
    // Weekly mode still uses this cadence so overdue weekly backups are caught.
    await Workmanager().registerPeriodicTask(
      kAutoBackupTaskUniqueName,
      kAutoBackupTaskName,
      frequency: const Duration(hours: 12),
      initialDelay: const Duration(minutes: 20),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
      constraints: Constraints(
        networkType:
            wifiOnly ? NetworkType.unmetered : NetworkType.connected,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 30),
    );
  }
}

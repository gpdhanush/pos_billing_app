import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pos_billing/app/localization/generated/app_localizations.dart';
import 'package:pos_billing/core/constants/app_constants.dart';
import 'package:pos_billing/core/database/repositories/settings_repository.dart';
import 'package:pos_billing/core/services/backup_service.dart';
import 'package:pos_billing/core/services/connectivity_service.dart';
import 'package:pos_billing/core/analytics/analytics_service.dart';
import 'package:pos_billing/core/notifications/notification_service.dart';
import 'package:pos_billing/core/services/backup_background.dart';
import 'package:pos_billing/core/services/backup_dirty_tracker.dart';
import 'package:pos_billing/core/utils/time.dart';

/// Runs auto-backup while the app is open, and keeps the OS background
/// worker (WorkManager) in sync so backups can still run when closed.
class BackupCoordinator {
  BackupCoordinator({
    required this.backupService,
    required this.settings,
    required this.connectivity,
    required this.dirtyTracker,
    required this.notifications,
    required this.analytics,
    this.debounce = const Duration(seconds: 8),
  });

  final BackupService backupService;
  final SettingsRepository settings;
  final ConnectivityService connectivity;
  final BackupDirtyTracker dirtyTracker;
  final NotificationService notifications;
  final AnalyticsService analytics;
  final Duration debounce;

  StreamSubscription<bool>? _sub;
  Timer? _debounceTimer;
  bool _running = false;
  bool _started = false;

  void start() {
    if (_started) return;
    _started = true;
    _sub = connectivity.onlineStream.listen((online) {
      if (online) _scheduleCheck();
    });
    _scheduleCheck();
    // Ensure periodic OS worker matches current settings (runs when closed).
    unawaited(BackupBackgroundScheduler.syncFromSettings(settings));
  }

  void dispose() {
    _debounceTimer?.cancel();
    _sub?.cancel();
    _started = false;
  }

  void _scheduleCheck() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      unawaited(maybeRunAutoBackup());
    });
  }

  /// Re-register / cancel the background worker after settings change.
  Future<void> syncBackgroundSchedule() =>
      BackupBackgroundScheduler.syncFromSettings(settings);

  Future<void> maybeRunAutoBackup({bool force = false}) async {
    if (_running) return;
    _running = true;
    try {
      final freq = await settings.get(SettingKeys.autoBackup) ?? 'off';
      if (!force && (freq == 'off' || freq.isEmpty)) return;

      final drive = backupService.drive;
      if (drive == null || !await drive.isSignedIn) return;

      final wifiOnly =
          await settings.getBool(SettingKeys.backupWifiOnly, fallback: true);
      if (wifiOnly && !await connectivity.isWifi) return;
      if (!await connectivity.hasInternetAccess()) return;

      // Drive upload needs a local DEK + existing envelope (no UI in background).
      if (!await backupService.crypto.hasLocalDek()) return;
      final envelope = await drive.downloadEnvelope();
      if (envelope == null) return;

      final dirty = await dirtyTracker.isDirty();
      if (!force && !dirty && !await _intervalElapsed(freq)) return;

      await analytics.logEvent('backup_auto_started');
      await backupService.createBackup(uploadToDrive: true);
      await settings.set(
        SettingKeys.lastAutoBackupAt,
        nowMillis().toString(),
      );
      await dirtyTracker.clearDirty();
      final localeCode =
          await settings.get(SettingKeys.localeCode) ?? 'en';
      final l10n = lookupAppLocalizations(Locale(localeCode));
      await notifications.showLocal(
        title: l10n.backupComplete,
        body: l10n.backupCompleteBody,
        id: 4101,
      );
      await analytics.logEvent('backup_auto_success');
    } catch (_) {
      await analytics.logEvent('backup_auto_failed');
      try {
        await analytics.recordError(
          'auto_backup_failed',
          reason: 'backup_coordinator',
        );
      } catch (_) {}
    } finally {
      _running = false;
    }
  }

  Future<bool> _intervalElapsed(String freq) async {
    final raw = await settings.get(SettingKeys.lastAutoBackupAt);
    final lastMs = int.tryParse(raw ?? '');
    if (lastMs == null) return true;
    final last = DateTime.fromMillisecondsSinceEpoch(lastMs);
    final now = DateTime.now();
    if (freq == 'daily') {
      return now.difference(last) >= const Duration(hours: 20);
    }
    if (freq == 'weekly') {
      return now.difference(last) >= const Duration(days: 6);
    }
    return false;
  }
}

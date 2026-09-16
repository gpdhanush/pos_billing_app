import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_billing/app/app.dart';
import 'package:pos_billing/core/ads/app_open_ad_manager.dart';
import 'package:pos_billing/core/ads/mobile_ads_init.dart';
import 'package:pos_billing/app/providers.dart';
import 'package:pos_billing/core/analytics/analytics_service.dart';
import 'package:pos_billing/core/database/app_database.dart';
import 'package:pos_billing/core/errors/app_error_handler.dart';
import 'package:pos_billing/core/notifications/notification_service.dart';
import 'package:pos_billing/core/services/app_log_service.dart';
import 'package:pos_billing/core/services/backup_background.dart';
import 'package:pos_billing/core/services/env_loader.dart';

Future<void> main() async {
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    AppErrorHandler.install();
    await AppLogService.init();
    await loadAppEnv();
    try {
      await ensureMobileAdsInitialized();
      // Preload so splash can show an app open ad when ready.
      unawaited(AppOpenAdManager.instance.loadAd());
    } catch (_) {
      // Ads are optional; app still runs if AdMob fails.
    }
    await AppLogService.info('App starting');

    // Open DB first so splash/settings can load, then show UI immediately.
    final db = await AppDatabase.open();
    final notifications = NotificationService();
    final analytics = AnalyticsService(notifications: notifications);

    runApp(
      ProviderScope(
        overrides: [
          databaseHolderProvider.overrideWith((ref) => db),
          analyticsServiceProvider.overrideWithValue(analytics),
          notificationServiceProvider.overrideWithValue(notifications),
        ],
        child: const PosApp(),
      ),
    );

    // Heavy plugins after first frame — never block the splash.
    unawaited(_initSecondaryServices(
      analytics: analytics,
      notifications: notifications,
    ));
  }, (error, stack) {
    AppLogService.crash(error, stack, 'runZonedGuarded');
    if (kDebugMode) {
      debugPrint('Zone error: $error\n$stack');
      return;
    }
    appCrashNotifier.value = AppCrashInfo.fromObject(error, stack);
  });
}

Future<void> _initSecondaryServices({
  required AnalyticsService analytics,
  required NotificationService notifications,
}) async {
  try {
    await BackupBackgroundScheduler.initialize();
  } catch (e) {
    unawaited(AppLogService.warn('WorkManager init failed: $e'));
  }

  var firebaseOk = false;
  try {
    await analytics.init();
    firebaseOk = analytics.isReady;
  } catch (e) {
    unawaited(AppLogService.warn('Analytics init failed: $e'));
    firebaseOk = false;
  }

  try {
    await notifications.init(firebaseAvailable: firebaseOk);
  } catch (e) {
    unawaited(AppLogService.warn('Notifications init failed: $e'));
  }

  if (firebaseOk) {
    unawaited(analytics.flushQueuedTelemetry());
    unawaited(notifications.refreshFcm());
  }
}

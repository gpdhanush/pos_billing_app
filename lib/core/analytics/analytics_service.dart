import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pos_billing/core/notifications/notification_service.dart';
import 'package:pos_billing/core/services/connectivity_service.dart';

/// Firebase Analytics + Crashlytics with offline queue.
///
/// Online  → send immediately.
/// Offline → append to a local NDJSON file (no PII).
/// Back online → flush once to Firebase, refresh FCM, then clear the file.
class AnalyticsService {
  AnalyticsService({
    ConnectivityService? connectivity,
    NotificationService? notifications,
  })  : _connectivity = connectivity ?? ConnectivityService(),
        _notifications = notifications;

  final ConnectivityService _connectivity;
  final NotificationService? _notifications;

  static const _queueFileName = 'firebase_telemetry_queue.jsonl';
  static const _maxQueueBytes = 512 * 1024;

  bool _ready = false;
  FirebaseAnalytics? _analytics;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _flushing = false;
  bool? _lastOnline;

  bool get isReady => _ready;

  static bool get _crashlyticsEnabled => kReleaseMode;

  Future<void> init() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _analytics = FirebaseAnalytics.instance;
      if (_crashlyticsEnabled) {
        FlutterError.onError = (details) {
          FlutterError.presentError(details);
          unawaited(
            recordError(
              details.exceptionAsString(),
              reason: 'flutter_error',
              fatal: true,
              stack: details.stack,
            ),
          );
        };
        PlatformDispatcher.instance.onError = (error, stack) {
          unawaited(
            recordError(
              error.toString(),
              reason: 'platform_error',
              fatal: true,
              stack: stack,
            ),
          );
          return true;
        };
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(true);
      } else {
        await FirebaseCrashlytics.instance
            .setCrashlyticsCollectionEnabled(false);
      }
      _ready = true;
      await _listenConnectivity();
      // Startup flush if already online.
      if (await _connectivity.hasInternetAccess()) {
        await flushQueuedTelemetry();
        await _notifications?.refreshFcm();
      }
    } catch (_) {
      _ready = false;
      _analytics = null;
    }
  }

  Future<void> dispose() async {
    await _connectivitySub?.cancel();
    _connectivitySub = null;
  }

  Future<void> logAppOpen() => logEvent('app_open');

  Future<void> logEvent(
    String name, {
    Map<String, Object>? parameters,
  }) async {
    // Callers must not pass PII (emails, names, phone numbers).
    final online = await _connectivity.hasInternetAccess();
    if (online && _ready && _analytics != null) {
      try {
        await _analytics!.logEvent(name: name, parameters: parameters);
        return;
      } catch (_) {
        // Fall through to queue.
      }
    }
    await _enqueue({
      't': 'event',
      'name': name,
      if (parameters != null && parameters.isNotEmpty) 'params': parameters,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<void> recordError(
    String message, {
    String? reason,
    bool fatal = false,
    StackTrace? stack,
  }) async {
    if (!_crashlyticsEnabled) return;

    final online = await _connectivity.hasInternetAccess();
    if (online && _ready) {
      try {
        await FirebaseCrashlytics.instance.recordError(
          Exception(message),
          stack ?? StackTrace.current,
          reason: reason,
          fatal: fatal,
        );
        return;
      } catch (_) {}
    }
    await _enqueue({
      't': 'error',
      'message': message,
      if (reason != null) 'reason': reason,
      'fatal': fatal,
      'at': DateTime.now().toUtc().toIso8601String(),
    });
  }

  /// Flush queued telemetry once, then clear the local file.
  Future<void> flushQueuedTelemetry() async {
    if (_flushing || !_ready) return;
    _flushing = true;
    try {
      final file = await _queueFile();
      if (!await file.exists()) return;
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        await file.writeAsString('', flush: true);
        return;
      }

      final lines = raw.split('\n').where((l) => l.trim().isNotEmpty);
      for (final line in lines) {
        try {
          final map = jsonDecode(line) as Map<String, dynamic>;
          final type = map['t'] as String?;
          if (type == 'event') {
            final name = map['name'] as String?;
            if (name == null || name.isEmpty) continue;
            final params = (map['params'] as Map?)?.cast<String, Object>();
            await _analytics?.logEvent(name: name, parameters: params);
          } else if (type == 'error') {
            if (!_crashlyticsEnabled) continue;
            final message = map['message'] as String? ?? 'queued_error';
            await FirebaseCrashlytics.instance.recordError(
              Exception(message),
              StackTrace.current,
              reason: map['reason'] as String? ?? 'queued',
              fatal: map['fatal'] == true,
            );
          }
        } catch (_) {
          // Skip corrupt lines; still clear queue after best-effort flush.
        }
      }

      // Clear file once after a single flush pass.
      await file.writeAsString('', flush: true);
    } catch (_) {
    } finally {
      _flushing = false;
    }
  }

  Future<void> _listenConnectivity() async {
    await _connectivitySub?.cancel();
    // Seed last-known state.
    _lastOnline = await _connectivity.hasInternetAccess();

    _connectivitySub = _connectivity.connectivityChanges.listen((_) async {
      final online = await _connectivity.hasInternetAccess();
      if (_lastOnline == online) return;
      _lastOnline = online;

      if (online) {
        // User came online → catch metrics directly path + one-shot flush.
        await logEvent('user_online');
        await flushQueuedTelemetry();
        await _notifications?.refreshFcm();
      } else {
        await _enqueue({
          't': 'event',
          'name': 'user_offline',
          'at': DateTime.now().toUtc().toIso8601String(),
        });
      }
    });
  }

  Future<File> _queueFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final logsDir = Directory(p.join(dir.path, 'logs'));
    if (!await logsDir.exists()) {
      await logsDir.create(recursive: true);
    }
    return File(p.join(logsDir.path, _queueFileName));
  }

  Future<void> _enqueue(Map<String, Object?> entry) async {
    try {
      final file = await _queueFile();
      if (await file.exists()) {
        final len = await file.length();
        if (len > _maxQueueBytes) {
          // Keep file bounded: drop oldest half by rewriting last chunk.
          final raw = await file.readAsString();
          final lines = raw.split('\n').where((l) => l.trim().isNotEmpty).toList();
          final keep = lines.skip(lines.length ~/ 2).join('\n');
          await file.writeAsString('$keep\n', flush: true);
        }
      }
      await file.writeAsString(
        '${jsonEncode(entry)}\n',
        mode: FileMode.append,
        flush: true,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Telemetry enqueue skipped: $e');
      }
    }
  }
}

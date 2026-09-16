import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
  } catch (_) {}
}

/// FCM + local notifications. Safe no-op when Firebase is not configured.
class NotificationService {
  NotificationService();

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool _firebaseReady = false;
  bool _fcmRefreshing = false;

  bool get isReady => _ready;

  Future<void> init({bool firebaseAvailable = false}) async {
    try {
      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings();
      await _local.initialize(
        settings: const InitializationSettings(android: android, iOS: ios),
      );
      const channel = AndroidNotificationChannel(
        'pos_backup',
        'Backup',
        description: 'Backup and restore notifications',
        importance: Importance.defaultImportance,
      );
      await _local
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);
      _ready = true;
    } catch (_) {
      _ready = false;
    }

    if (!firebaseAvailable) return;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      await messaging.subscribeToTopic('pos_all_users');
      await messaging.subscribeToTopic('pos_android_users');
      await messaging.subscribeToTopic('pos_app_updates');
      FirebaseMessaging.onMessage.listen((message) {
        final title = message.notification?.title ?? 'POS Billing';
        final body = message.notification?.body ?? '';
        if (body.isNotEmpty) {
          showLocal(title: title, body: body, id: message.hashCode);
        }
      });
      _firebaseReady = true;
      await refreshFcm();
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM init skipped: $e');
      }
      _firebaseReady = false;
    }
  }

  /// Refresh FCM token + re-subscribe topics once when back online.
  Future<void> refreshFcm() async {
    if (!_firebaseReady || _fcmRefreshing) return;
    _fcmRefreshing = true;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.getToken();
      await messaging.subscribeToTopic('pos_all_users');
      await messaging.subscribeToTopic('pos_android_users');
      await messaging.subscribeToTopic('pos_app_updates');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('FCM refresh skipped: $e');
      }
    } finally {
      _fcmRefreshing = false;
    }
  }

  Future<void> showLocal({
    required String title,
    required String body,
    int id = 0,
  }) async {
    if (!_ready) return;
    try {
      await _local.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'pos_backup',
            'Backup',
            channelDescription: 'Backup and restore notifications',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (_) {}
  }

  bool get firebaseReady => _firebaseReady;
}

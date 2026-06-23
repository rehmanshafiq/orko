import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:orko_hubco/core/router/app_router.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';

import '../../firebase_options.dart';

/// Background/terminated message handler. Must be a top-level (or static)
/// function annotated with `@pragma('vm:entry-point')` because it runs in a
/// separate isolate spun up by the OS.
///
/// For `notification` messages Android renders the system tray notification
/// automatically, so there's nothing to draw here — we just ensure Firebase is
/// initialised in this isolate (required before touching any Firebase API).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // Already initialised in this isolate — ignore.
  }
  log('[Push] Background message: ${message.messageId} '
      'data=${message.data} notif=${message.notification?.title}');
}

/// Owns all Firebase Cloud Messaging wiring for the app:
/// permission, token lifecycle, foreground display, and tap routing.
class PushNotificationService {
  PushNotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// High-importance channel used for both foreground local notifications and
  /// (via the manifest meta-data) background system notifications. The id must
  /// match `default_notification_channel_id` in AndroidManifest.xml.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'high_importance_channel',
    'General Notifications',
    description: 'Booking, charging and account notifications.',
    importance: Importance.high,
  );

  /// One-time setup. Safe to call multiple times (no-ops after the first).
  /// Never throws — push is best-effort and must not block app startup.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    try {
      await _initLocalNotifications();
      await _requestPermission();

      // iOS shows foreground notifications natively; opt in. (No-op on Android.)
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _syncToken();
      _messaging.onTokenRefresh.listen(_onTokenRefresh);

      // Foreground messages: Android won't auto-display, so draw it ourselves.
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);

      // App opened from background by tapping a notification.
      FirebaseMessaging.onMessageOpenedApp.listen(_onMessageOpened);

      // App launched from terminated by tapping a notification.
      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) {
        _deferOpen(initialMessage);
      }
    } catch (e, st) {
      log('[Push] initialize failed: $e\n$st');
    }
  }

  /// Returns the freshest token, persisting it. Falls back to the cached value.
  Future<String?> refreshToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await AppStorage.setFcmToken(token);
      }
      return token ?? (AppStorage.fcmToken.isEmpty ? null : AppStorage.fcmToken);
    } catch (e) {
      log('[Push] getToken failed: $e');
      return AppStorage.fcmToken.isEmpty ? null : AppStorage.fcmToken;
    }
  }

  // ── Setup helpers ─────────────────────────────────────────────────────────

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('ic_notification');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _localNotifications.initialize(
      settings: const InitializationSettings(android: androidInit, iOS: iosInit),
      onDidReceiveNotificationResponse: (response) {
        _openNotificationsScreen();
      },
    );

    // Create the Android channel up front so importance is respected.
    await _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  Future<void> _requestPermission() async {
    try {
      final settings = await _messaging.requestPermission();
      log('[Push] permission: ${settings.authorizationStatus}');
    } catch (e) {
      log('[Push] requestPermission failed: $e');
    }
  }

  Future<void> _syncToken() async {
    final token = await refreshToken();
    log('[Push] FCM token: ${token == null ? 'unavailable' : '${token.substring(0, token.length.clamp(0, 12))}…'}');
  }

  Future<void> _onTokenRefresh(String token) async {
    await AppStorage.setFcmToken(token);
    log('[Push] token refreshed');
    // NOTE: there is no dedicated "update device token" endpoint yet. The fresh
    // token is persisted and will be sent on the next login. See the backend
    // notes for the recommended token-refresh endpoint.
  }

  // ── Message handling ──────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return; // data-only — nothing to display.

    _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: 'ic_notification',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: message.data['route']?.toString(),
    );
  }

  void _onMessageOpened(RemoteMessage message) => _openNotificationsScreen();

  /// Cold-start taps fire before the router/first frame are ready, so defer.
  void _deferOpen(RemoteMessage message) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 1200), _openNotificationsScreen);
    });
  }

  void _openNotificationsScreen() {
    try {
      AppRouter.router.push('/notifications');
    } catch (e) {
      log('[Push] navigation to notifications failed: $e');
    }
  }
}

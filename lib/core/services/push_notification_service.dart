import 'dart:developer';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/router/app_router.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/delete_device_token_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/register_device_token_usecase.dart';

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
    // On iOS the FCM token can't be minted until APNs hands the app a device
    // token, which arrives asynchronously after registration. Wait briefly for
    // it and log the outcome — if this stays null, the problem is APNs-side
    // (entitlement, provisioning, or Apple's sandbox), not FCM.
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      String? apnsToken;
      for (var attempt = 0; attempt < 10; attempt++) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      log('[Push] APNs token: ${apnsToken ?? 'NOT SET after 10s — device never registered with APNs'}');
    }

    final token = await refreshToken();
    // Full token in debug builds so it can be pasted into test tooling;
    // truncated in release to keep it out of production logs.
    log(kDebugMode
        ? '[Push] FCM token: $token'
        : '[Push] FCM token: ${token == null ? 'unavailable' : '${token.substring(0, token.length.clamp(0, 12))}…'}');
    await _maybeRegisterToken(token);
  }

  Future<void> _onTokenRefresh(String token) async {
    await AppStorage.setFcmToken(token);
    log('[Push] token refreshed');
    await _maybeRegisterToken(token);
  }

  /// Upserts the token to the backend (`POST device-token/`) when the user is
  /// authenticated and the token actually changed since the last successful
  /// upsert. Best-effort: failures are logged, never thrown. When the user
  /// isn't logged in the token is simply persisted — the next login sends it.
  Future<void> _maybeRegisterToken(String? token) async {
    if (token == null || token.isEmpty) return;
    if (!_isAuthenticated) return;
    if (token == AppStorage.fcmTokenRegistered) return;

    try {
      final result = await sl<RegisterDeviceTokenUseCase>()(token);
      result.fold(
        (failure) => log('[Push] device-token register failed: ${failure.message}'),
        (_) async {
          await AppStorage.setFcmTokenRegistered(token);
          log('[Push] device-token registered');
        },
      );
    } catch (e) {
      log('[Push] device-token register error: $e');
    }
  }

  /// Clears the device token on the backend (`DELETE device-token/`). Call on
  /// logout *before* the session token is cleared. Best-effort.
  Future<void> unregisterTokenFromBackend() async {
    // Clear the local dedup marker regardless, so a re-login re-registers.
    await AppStorage.setFcmTokenRegistered('');
    if (!_isAuthenticated) return;
    try {
      final result = await sl<DeleteDeviceTokenUseCase>()(const NoParams());
      result.fold(
        (failure) => log('[Push] device-token delete failed: ${failure.message}'),
        (_) => log('[Push] device-token cleared'),
      );
    } catch (e) {
      log('[Push] device-token delete error: $e');
    }
  }

  /// True when a session access token is present (the device-token endpoints
  /// require auth). Reads storage directly to avoid a core→feature dependency.
  bool get _isAuthenticated {
    final token = GetStorage().read<String>(StorageConstants.accessToken);
    return token != null && token.isNotEmpty;
  }

  // ── Message handling ──────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    final notification = message.notification;
    if (notification == null) return; // data-only — nothing to display.

    // iOS already presents foreground pushes natively via
    // setForegroundNotificationPresentationOptions — drawing a local
    // notification here too would duplicate it. Android needs the manual draw.
    if (defaultTargetPlatform == TargetPlatform.iOS) return;

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

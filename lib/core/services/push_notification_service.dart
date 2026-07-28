import 'dart:async';

import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_notification_controller.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_service_starter.dart';
import 'package:orko_hubco/core/services/secure_store.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/router/app_router.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';
import 'package:orko_hubco/features/booking/presentation/pages/my_bookings_page.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/bottom_nav_shell.dart';
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
  AppLogger.d('[Push] Background message: ${message.messageId} '
      'data=${message.data} notif=${message.notification?.title}');

  // Session started while the app was backgrounded/killed: bring up the ongoing
  // charging notification via a foreground service. High-priority FCM messages
  // are granted a temporary allowance to start one. (Stop is handled by the
  // service's own poll detecting the session ended.)
  if (liveSessionSignalForTitle(message.notification?.title) ==
      LiveSessionSignal.start) {
    await startLiveChargingService();
  }
}

/// Whether a notification title marks a live charging session starting, ending,
/// or neither — used to arm/tear down the live-charging notification.
enum LiveSessionSignal { start, stop, none }

/// Maps a notification title to a [LiveSessionSignal]. Titles mirror the
/// backend's CHARGING_SESSION / LIVE_SESSION message sets, matched
/// case-insensitively.
LiveSessionSignal liveSessionSignalForTitle(String? title) {
  final key = title?.trim().toLowerCase();
  if (key == null || key.isEmpty) return LiveSessionSignal.none;
  switch (key) {
    case 'live session started':
    case 'charging started':
      return LiveSessionSignal.start;
    case 'live session stopped':
    case 'charging complete':
    case 'charging completed':
      return LiveSessionSignal.stop;
  }
  return LiveSessionSignal.none;
}

/// Owns all Firebase Cloud Messaging wiring for the app:
/// permission, token lifecycle, foreground display, and tap routing.
class PushNotificationService {
  PushNotificationService();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// The message (if any) that launched the app from a terminated (killed)
  /// state via a notification tap. Captured as a Future at the very top of
  /// [initialize] — *before* the slow token sync — and awaited by
  /// [applyLaunchIntent] once the splash reaches the shell. Storing the Future
  /// (rather than the resolved value) removes the startup race: the splash can
  /// call [applyLaunchIntent] before `getInitialMessage()` has resolved and
  /// still get the right result.
  Future<RemoteMessage?>? _initialMessageFuture;

  /// Guards [applyLaunchIntent] so the cold-start deep link fires at most once.
  bool _launchIntentApplied = false;

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

    // Capture the launch tap FIRST, before the slow steps below (iOS's
    // _syncToken waits up to 10s for an APNs token). This runs synchronously
    // when initialize() is kicked off at startup, so the Future is available
    // long before the splash calls [applyLaunchIntent] — no startup race.
    _initialMessageFuture = _messaging.getInitialMessage();

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

      // The terminated (killed) launch tap is captured up front via
      // _initialMessageFuture and applied by the splash — see
      // [applyLaunchIntent]. Nothing to do here.
    } catch (e, st) {
      AppLogger.d('[Push] initialize failed: $e\n$st');
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
      AppLogger.d('[Push] getToken failed: $e');
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
      // The payload carries the notification title (set in [_onForegroundMessage])
      // so a tap can deep-link to the right Bookings sub-tab.
      onDidReceiveNotificationResponse: (response) {
        _handleNotificationTap(title: response.payload);
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
      AppLogger.d('[Push] permission: ${settings.authorizationStatus}');
    } catch (e) {
      AppLogger.d('[Push] requestPermission failed: $e');
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
      // Device tokens are identifiers — full value only in debug, truncated
      // otherwise (mirrors the FCM-token handling below).
      AppLogger.d(kDebugMode
          ? '[Push] APNs token: ${apnsToken ?? 'NOT SET after 10s — device never registered with APNs'}'
          : '[Push] APNs token: ${apnsToken == null ? 'unavailable' : '${apnsToken.substring(0, apnsToken.length.clamp(0, 12))}…'}');
    }

    final token = await refreshToken();
    // Full token in debug builds so it can be pasted into test tooling;
    // truncated in release to keep it out of production logs.
    AppLogger.d(kDebugMode
        ? '[Push] FCM token: $token'
        : '[Push] FCM token: ${token == null ? 'unavailable' : '${token.substring(0, token.length.clamp(0, 12))}…'}');
    await _maybeRegisterToken(token);
  }

  Future<void> _onTokenRefresh(String token) async {
    await AppStorage.setFcmToken(token);
    AppLogger.d('[Push] token refreshed');
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
        (failure) => AppLogger.d('[Push] device-token register failed: ${failure.message}'),
        (_) async {
          await AppStorage.setFcmTokenRegistered(token);
          AppLogger.d('[Push] device-token registered');
        },
      );
    } catch (e) {
      AppLogger.d('[Push] device-token register error: $e');
    }
  }

  /// Re-registers the FCM token under the newly active session. Call after a
  /// successful login / OTP verification: [initialize] only runs once per app
  /// launch, so a logout→login within the same run would otherwise leave the
  /// new session without a device token until the next cold start. Best-effort.
  Future<void> registerTokenForSession() async {
    try {
      final token = await refreshToken();
      await _maybeRegisterToken(token);
    } catch (e) {
      AppLogger.d('[Push] post-login token sync failed: $e');
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
        (failure) => AppLogger.d('[Push] device-token delete failed: ${failure.message}'),
        (_) => AppLogger.d('[Push] device-token cleared'),
      );
    } catch (e) {
      AppLogger.d('[Push] device-token delete error: $e');
    }
  }

  /// True when a session access token is present (the device-token endpoints
  /// require auth). Reads storage directly to avoid a core→feature dependency.
  bool get _isAuthenticated {
    final token = SecureStore.instance.read(StorageConstants.accessToken);
    return token != null && token.isNotEmpty;
  }

  // ── Message handling ──────────────────────────────────────────────────────

  void _onForegroundMessage(RemoteMessage message) {
    // Log the full payload on both iOS and Android so foreground pushes can be
    // inspected regardless of platform (iOS returns early below to avoid a
    // duplicate local notification, but we still want the payload in the logs).
    AppLogger.d('[Push] Foreground message: ${message.messageId} '
        'data=${message.data} '
        'notif.title=${message.notification?.title} '
        'notif.body=${message.notification?.body}');

    // Arm / tear down the live-charging notification (before the iOS early
    // return below, so iOS drives its Live Activity too).
    _handleLiveSessionSignal(message.notification?.title);

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
          // BigText style so expanding the notification reveals the full body
          // instead of Android's default two-line truncation.
          styleInformation: BigTextStyleInformation(
            notification.body ?? '',
            contentTitle: notification.title,
          ),
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      // Carry the title so the tap handler can deep-link to the matching
      // Bookings sub-tab (see [_handleNotificationTap]).
      payload: notification.title,
    );
  }

  void _onMessageOpened(RemoteMessage message) {
    final title = message.notification?.title;
    // Tapping a start/stop push also arms/tears down the live notification.
    _handleLiveSessionSignal(title);
    _handleNotificationTap(title: title);
  }

  /// Arms or tears down the live-charging notification for a live-session
  /// start/stop [title]. Best-effort and fire-and-forget.
  void _handleLiveSessionSignal(String? title) {
    switch (liveSessionSignalForTitle(title)) {
      case LiveSessionSignal.start:
        unawaited(sl<LiveChargingNotificationController>().onSessionStartSignal());
        break;
      case LiveSessionSignal.stop:
        unawaited(sl<LiveChargingNotificationController>().onSessionStopSignal());
        break;
      case LiveSessionSignal.none:
        break;
    }
  }

  /// Applies a pending cold-start (killed-app) notification deep-link, if any,
  /// and returns whether it performed navigation.
  ///
  /// The splash flow awaits this *before* it navigates to the default home
  /// shell: when it returns true the splash leaves navigation to us (a single
  /// declarative `go`, so nothing clobbers it); when false the splash proceeds
  /// to home as usual. Awaits [_initialMessageFuture], so it works even if
  /// `getInitialMessage()` hasn't resolved yet (the slow token sync can outlast
  /// the splash). A null message means the app wasn't launched from a tap.
  Future<bool> applyLaunchIntent() async {
    if (_launchIntentApplied) return false;
    final future = _initialMessageFuture;
    if (future == null) return false;
    _launchIntentApplied = true;

    RemoteMessage? message;
    try {
      message = await future;
    } catch (e) {
      AppLogger.d('[Push] getInitialMessage failed: $e');
      return false;
    }
    // Normal cold start (not opened from a notification): let the splash route
    // to home as usual.
    if (message == null) return false;

    final tab = _bookingTabForTitle(message.notification?.title);
    if (tab != null) {
      _openBookingsTab(tab);
    } else {
      // Non-booking launch tap: put the home shell underneath, then open the
      // notifications list on top so Back returns to home.
      _openNotificationsFromLaunch();
    }
    return true;
  }

  /// Routes a notification tap: booking / charging notifications deep-link into
  /// the matching Bookings sub-tab (by [title]); everything else falls back to
  /// the notifications list.
  void _handleNotificationTap({String? title}) {
    final tab = _bookingTabForTitle(title);
    if (tab != null) {
      _openBookingsTab(tab);
    } else {
      _openNotificationsScreen();
    }
  }

  /// Maps a notification [title] to the Bookings sub-tab it should open, or null
  /// when the title isn't a booking/charging notification we deep-link.
  ///
  /// Titles mirror the backend's BOOKING / CHARGING_SESSION / LIVE_SESSION
  /// message sets. Matched case-insensitively so minor casing drift is tolerated.
  BookingTab? _bookingTabForTitle(String? title) {
    final key = title?.trim().toLowerCase();
    if (key == null || key.isEmpty) return null;
    switch (key) {
      // Reserved-but-not-started bookings live in the Upcoming tab.
      case 'booking received':
      case 'booking confirmed':
      case 'booking rescheduled':
        return BookingTab.upcoming;
      // A session that is (about to be) live lives in the Live/Active tab.
      case 'charging started':
      case 'live session started':
        return BookingTab.active;
      // Finished / cancelled / rejected outcomes live in the History tab.
      case 'booking rejected':
      case 'booking cancelled':
      case 'charging complete':
      case 'charging completed':
      case 'live session stopped':
        return BookingTab.history;
    }
    return null;
  }

  /// Switches to the Bookings bottom-nav tab and lands it on [tab]. Bumps
  /// [BottomNavShell.bookingsRefreshTick] so the page rebuilds and picks up the
  /// pending tab even when the branch was already alive in the indexed stack.
  void _openBookingsTab(BookingTab tab) {
    try {
      MyBookingsPage.pendingInitialTab = tab;
      BottomNavShell.bookingsRefreshTick.value++;
      AppRouter.router.go('/bookings');
    } catch (e) {
      AppLogger.d('[Push] navigation to bookings failed: $e');
    }
  }

  void _openNotificationsScreen() {
    try {
      AppRouter.router.push('/notifications');
    } catch (e) {
      AppLogger.d('[Push] navigation to notifications failed: $e');
    }
  }

  /// Cold-start variant of [_openNotificationsScreen]: the app launched onto
  /// the splash, so there's no home under the stack. Establish the home shell
  /// first, then push the notifications list on top of it.
  void _openNotificationsFromLaunch() {
    try {
      AppRouter.router.go('/home');
      AppRouter.router.push('/notifications');
    } catch (e) {
      AppLogger.d('[Push] launch navigation to notifications failed: $e');
    }
  }
}

import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/router/app_router.dart';
import 'package:orko_hubco/core/services/live_charging/ios_live_activity.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_keys.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_notification_content.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_service_starter.dart';
import 'package:orko_hubco/core/services/live_charging/live_session_fetcher.dart';
import 'package:orko_hubco/core/services/secure_store.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';
import 'package:orko_hubco/features/booking/presentation/pages/my_bookings_page.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/bottom_nav_shell.dart';

/// Owns the live-charging "now playing" notification on the main isolate:
///
/// * **Android** — runs a foreground service ([LiveChargingTaskHandler]) that
///   polls `live-session/` and keeps an ongoing, non-dismissible notification
///   in sync; survives app backgrounding.
/// * **iOS** — drives a Live Activity (ActivityKit) via [IosLiveActivity],
///   polling from the main isolate while the app is alive. (Continuous
///   background updates require the backend to push to the activity token.)
///
/// It's armed by a live-session **start** FCM signal (or an app-launch check)
/// and torn down by a **stop** signal or a poll that reports the session ended.
/// Tapping the notification deep-links to the My Charging → Live tab.
class LiveChargingNotificationController with WidgetsBindingObserver {
  LiveChargingNotificationController();

  final LiveSessionFetcher _fetcher = LiveSessionFetcher();
  final IosLiveActivity _iosActivity = IosLiveActivity();

  bool _initialized = false;
  bool _active = false;

  /// iOS-only poll (Android polling lives in the foreground-service isolate).
  Timer? _iosPoll;
  static const Duration _pollInterval = Duration(seconds: 5);

  /// One-time setup. Configures the foreground task, opens the cross-isolate
  /// communication port, and wires the data callback. Never throws.
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    try {
      // Re-check on resume so a session that started while iOS had the app
      // backgrounded (where a Live Activity can't be started) surfaces as soon
      // as the app is opened again.
      WidgetsBinding.instance.addObserver(this);
      FlutterForegroundTask.initCommunicationPort();
      FlutterForegroundTask.addTaskDataCallback(_onTaskData);
      if (Platform.isAndroid) {
        FlutterForegroundTask.init(
          androidNotificationOptions: AndroidNotificationOptions(
            channelId: LiveChargingKeys.channelId,
            channelName: LiveChargingKeys.channelName,
            channelDescription: LiveChargingKeys.channelDescription,
            // Silent + low importance: the ~10 s updates must never buzz.
            channelImportance: NotificationChannelImportance.LOW,
            priority: NotificationPriority.LOW,
            onlyAlertOnce: true,
          ),
          iosNotificationOptions: const IOSNotificationOptions(
            showNotification: false,
          ),
          foregroundTaskOptions: ForegroundTaskOptions(
            eventAction: ForegroundTaskEventAction.repeat(
              _pollInterval.inMilliseconds,
            ),
            autoRunOnBoot: false,
            allowWakeLock: true,
            allowWifiLock: true,
          ),
        );
      }
    } catch (e) {
      AppLogger.d('[LiveCharging] initialize failed: $e');
    }
  }

  /// At app launch: if a session is already running, bring up the notification.
  Future<void> checkOnLaunch() async {
    try {
      if (!await _isAuthenticated()) return;
      // A service left running from a previous run means we're already active.
      if (Platform.isAndroid && await FlutterForegroundTask.isRunningService) {
        _active = true;
        return;
      }
      final session = await _fetcher.fetch();
      if (session != null && session.active) {
        await _startActive(known: session);
      }
    } catch (e) {
      AppLogger.d('[LiveCharging] checkOnLaunch failed: $e');
    }
  }

  /// A live-session **start** push arrived (foreground/background/killed).
  Future<void> onSessionStartSignal() => _startActive();

  /// A live-session **stop** push arrived. The push itself renders the
  /// "Charging Complete" system notification, so we just tear the live UI down.
  Future<void> onSessionStopSignal() => _stop();

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onAppResumed());
    }
  }

  /// On foreground return: revive the iOS poll (suspended while backgrounded)
  /// and pick up a session that started while the app was away.
  Future<void> _onAppResumed() async {
    if (Platform.isIOS && _active && _iosPoll == null) {
      _iosPoll = Timer.periodic(_pollInterval, (_) => _iosTick());
    }
    if (!_active) {
      await checkOnLaunch();
    }
  }

  /// Consumes the "open Live tab" intent recorded when the ongoing notification
  /// was tapped from a cold start (app was killed, service still running).
  /// Called by the splash once it has navigated to the shell.
  Future<void> routePendingOpenLiveTabIfAny() async {
    try {
      final pending =
          await FlutterForegroundTask.getData<bool>(key: LiveChargingKeys.pendingOpenLive) ??
              false;
      if (!pending) return;
      await FlutterForegroundTask.removeData(key: LiveChargingKeys.pendingOpenLive);
      // Defer a frame so the shell is mounted before we switch branches.
      WidgetsBinding.instance.addPostFrameCallback((_) => _openLiveTab());
    } catch (e) {
      AppLogger.d('[LiveCharging] routePendingOpenLive failed: $e');
    }
  }

  // ── Internals ──────────────────────────────────────────────────────────────

  Future<void> _startActive({LiveSessionEntity? known}) async {
    if (_active) return;
    if (!await _isAuthenticated()) return;

    var session = known;
    session ??= await _fetcher.fetch();

    // Start signal but the session already ended — make sure we're torn down.
    if (session != null && !session.active) {
      await _stop();
      return;
    }

    final content = (session != null && session.active)
        ? buildActiveContent(session)
        : _placeholderContent();

    _active = true;
    if (Platform.isAndroid) {
      await _startAndroidService(content);
    } else if (Platform.isIOS) {
      await _startIosActivity(content);
    }
  }

  Future<void> _startAndroidService(
    LiveChargingNotificationContent content,
  ) async {
    // Shared with the FCM-background start path (session started while killed).
    await startLiveChargingService(title: content.title, text: content.text);
  }

  Future<void> _startIosActivity(
    LiveChargingNotificationContent content,
  ) async {
    if (!await _iosActivity.isSupported()) {
      _active = false;
      return;
    }
    await _iosActivity.start(content.data);
    _iosPoll?.cancel();
    _iosPoll = Timer.periodic(_pollInterval, (_) => _iosTick());
  }

  Future<void> _iosTick() async {
    final session = await _fetcher.fetch();
    if (session == null) return; // transient failure — keep last state.
    if (session.active) {
      await _iosActivity.update(buildActiveContent(session).data);
    } else {
      await _iosActivity.end(buildCompletedContent(session).data);
      await _stop();
    }
  }

  Future<void> _stop() async {
    _active = false;
    _iosPoll?.cancel();
    _iosPoll = null;
    try {
      if (Platform.isAndroid) {
        if (await FlutterForegroundTask.isRunningService) {
          await FlutterForegroundTask.stopService();
        }
      } else if (Platform.isIOS) {
        await _iosActivity.end();
      }
    } catch (e) {
      AppLogger.d('[LiveCharging] stop failed: $e');
    }
  }

  void _onTaskData(Object data) {
    if (data == LiveChargingKeys.openLiveSignal) {
      _openLiveTab();
    } else if (data == LiveChargingKeys.completedSignal) {
      // The service posted the terminal notification and stopped itself.
      _active = false;
      _iosPoll?.cancel();
      _iosPoll = null;
    }
    // activeSignal: nothing to do on the main isolate (Android draws from the
    // service isolate; iOS drives its own poll).
  }

  /// Deep-links to My Charging → Live, reusing the same mechanism as the FCM
  /// notification taps ([MyBookingsPage.pendingInitialTab] + the bookings
  /// refresh tick + a go_router branch switch).
  void _openLiveTab() {
    try {
      MyBookingsPage.pendingInitialTab = BookingTab.active;
      BottomNavShell.bookingsRefreshTick.value++;
      AppRouter.router.go('/bookings');
    } catch (e) {
      AppLogger.d('[LiveCharging] open live tab failed: $e');
    }
  }

  LiveChargingNotificationContent _placeholderContent() =>
      const LiveChargingNotificationContent(
        title: '⚡ Charging session',
        text: 'Your charging session is live',
        data: {'state': 'active'},
      );

  Future<bool> _isAuthenticated() async {
    try {
      await SecureStore.instance.init();
      final token = SecureStore.instance.read(StorageConstants.accessToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

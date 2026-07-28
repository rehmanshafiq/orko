import 'dart:ui';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_keys.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_notification_content.dart';
import 'package:orko_hubco/core/services/live_charging/live_session_fetcher.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Entry point for the foreground-service isolate. Must be a top-level function
/// annotated `@pragma('vm:entry-point')` so it survives tree-shaking / AOT and
/// can be looked up by name when the service isolate spins up.
@pragma('vm:entry-point')
void startLiveChargingCallback() {
  FlutterForegroundTask.setTaskHandler(LiveChargingTaskHandler());
}

/// Polls `live-session/` every [_pollInterval] from the foreground-service
/// isolate and keeps the ongoing notification in sync. This isolate starts with
/// none of the app's singletons, so [LiveSessionFetcher] re-initialises the
/// minimal network stack itself. When the session ends it posts the terminal
/// "Charging Complete" notification and stops the service.
class LiveChargingTaskHandler extends TaskHandler {
  final LiveSessionFetcher _fetcher = LiveSessionFetcher();
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// Guards the completion path so we post the terminal notification / stop the
  /// service exactly once even if a late tick also reports inactive.
  bool _finished = false;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Background isolate: register plugins before any platform-channel call.
    DartPluginRegistrant.ensureInitialized();
    await _initLocalNotifications();
    // Draw real figures as soon as possible instead of waiting a full interval.
    await _tick();
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    _tick();
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {}

  /// Notification tapped: bring the app forward and record intent to open the
  /// Live tab. The controller consumes [LiveChargingKeys.pendingOpenLive] on
  /// resume / launch, and also gets a live nudge via [sendDataToMain] when the
  /// main isolate is still alive.
  @override
  void onNotificationPressed() {
    FlutterForegroundTask.saveData(
      key: LiveChargingKeys.pendingOpenLive,
      value: true,
    );
    FlutterForegroundTask.sendDataToMain(LiveChargingKeys.openLiveSignal);
    FlutterForegroundTask.launchApp();
  }

  Future<void> _tick() async {
    if (_finished) return;

    final session = await _fetcher.fetch();
    // Null = a transient fetch failure (network/auth). Keep the last-known
    // notification rather than tearing the service down on a blip.
    if (session == null) return;

    if (session.active) {
      final content = buildActiveContent(session);
      await FlutterForegroundTask.updateService(
        notificationTitle: content.title,
        notificationText: content.text,
      );
      // Let the main isolate (if alive) refresh the iOS Live Activity / UI.
      FlutterForegroundTask.sendDataToMain(LiveChargingKeys.activeSignal);
      return;
    }

    // Session ended (while backgrounded or otherwise): surface the terminal
    // notification, tell the main isolate, and stop the service.
    _finished = true;
    await _postCompleted(buildCompletedContent(session));
    FlutterForegroundTask.sendDataToMain(LiveChargingKeys.completedSignal);
    await FlutterForegroundTask.stopService();
  }

  Future<void> _initLocalNotifications() async {
    const androidInit = AndroidInitializationSettings('ic_notification');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    try {
      await _localNotifications.initialize(
        settings:
            const InitializationSettings(android: androidInit, iOS: iosInit),
      );
    } catch (e) {
      AppLogger.d('[LiveTask] local notifications init failed: $e');
    }
  }

  /// Posts the dismissible "Charging Complete" notification on the app's
  /// existing high-importance channel (created on the main isolate at startup).
  Future<void> _postCompleted(LiveChargingNotificationContent content) async {
    try {
      await _localNotifications.show(
        id: LiveChargingKeys.completedNotificationId,
        title: content.title,
        body: content.text,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'high_importance_channel',
            'General Notifications',
            channelDescription: 'Booking, charging and account notifications.',
            importance: Importance.high,
            priority: Priority.high,
            icon: 'ic_notification',
          ),
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      AppLogger.d('[LiveTask] post completed failed: $e');
    }
  }
}

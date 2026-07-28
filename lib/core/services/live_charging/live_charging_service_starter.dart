import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_keys.dart';
import 'package:orko_hubco/core/services/live_charging/live_charging_task_handler.dart'
    show startLiveChargingCallback;
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Configures and starts the Android live-charging foreground service.
///
/// Deliberately dependency-light (only `flutter_foreground_task` + keys) so it
/// can run from the **FCM background isolate** — which is how a session that
/// starts while the app is killed brings the notification up. High-priority FCM
/// messages are granted a temporary allowance to start a foreground service.
///
/// No-op on iOS (Live Activities are driven from the main isolate) and when the
/// service is already running.
@pragma('vm:entry-point')
Future<void> startLiveChargingService({String? title, String? text}) async {
  if (!Platform.isAndroid) return;
  try {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: LiveChargingKeys.channelId,
        channelName: LiveChargingKeys.channelName,
        channelDescription: LiveChargingKeys.channelDescription,
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    if (await FlutterForegroundTask.isRunningService) {
      await FlutterForegroundTask.updateService(
        notificationTitle: title ?? '⚡ Charging session',
        notificationText: text ?? 'Your charging session is live',
      );
      return;
    }

    await FlutterForegroundTask.startService(
      serviceId: LiveChargingKeys.serviceId,
      serviceTypes: [ForegroundServiceTypes.dataSync],
      notificationTitle: title ?? '⚡ Charging session',
      notificationText: text ?? 'Your charging session is live',
      notificationIcon: const NotificationIcon(
        metaDataName: 'com.orko_hubco.live_charging.NOTIFICATION_ICON',
      ),
      callback: startLiveChargingCallback,
    );
  } catch (e) {
    AppLogger.d('[LiveCharging] service start failed: $e');
  }
}

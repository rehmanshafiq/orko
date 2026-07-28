/// Constants shared between the foreground-service isolate
/// ([LiveChargingTaskHandler]) and the main-isolate
/// [LiveChargingNotificationController]: notification / service ids, the
/// cross-isolate data signals, and the persisted "open Live tab" flag.
class LiveChargingKeys {
  LiveChargingKeys._();

  /// Foreground-service id (also the id of its ongoing notification).
  static const int serviceId = 4210;

  /// Id of the one-off, dismissible "Charging Complete" notification.
  static const int completedNotificationId = 4211;

  /// Silent, low-importance channel for the ongoing charging notification, so
  /// the ~10 s updates never buzz or make a sound.
  static const String channelId = 'live_charging_channel';
  static const String channelName = 'Live Charging';
  static const String channelDescription =
      'Shows your charging session progress while it is running.';

  // ── Cross-isolate signals (sendDataToMain) ────────────────────────────────
  static const String activeSignal = 'live_charging_active';
  static const String completedSignal = 'live_charging_completed';
  static const String openLiveSignal = 'live_charging_open_live';

  /// Persisted flag (FlutterForegroundTask.saveData) set when the ongoing
  /// notification is tapped, so a cold-started app still routes to the Live tab.
  static const String pendingOpenLive = 'live_charging_pending_open_live';
}

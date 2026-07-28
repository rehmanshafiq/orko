import 'dart:io';

import 'package:flutter/services.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Thin bridge to the native iOS Live Activity (ActivityKit), driven over a
/// [MethodChannel]. Every call is a no-op on non-iOS platforms and on iOS
/// versions below 16.1 (where the native side reports unsupported), so callers
/// can invoke it unconditionally.
class IosLiveActivity {
  IosLiveActivity();

  static const MethodChannel _channel =
      MethodChannel('orko/live_charging_activity');

  /// Whether a Live Activity can be shown (iOS 16.1+, activities enabled).
  Future<bool> isSupported() async {
    if (!Platform.isIOS) return false;
    try {
      final result = await _channel.invokeMethod<bool>('isSupported');
      return result ?? false;
    } catch (e) {
      AppLogger.d('[LiveActivity] isSupported failed: $e');
      return false;
    }
  }

  /// Starts a Live Activity with the initial [data] (all string values, from
  /// [LiveChargingNotificationContent.data]).
  Future<void> start(Map<String, String> data) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('start', data);
    } catch (e) {
      AppLogger.d('[LiveActivity] start failed: $e');
    }
  }

  /// Updates the running Live Activity with fresh [data].
  Future<void> update(Map<String, String> data) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('update', data);
    } catch (e) {
      AppLogger.d('[LiveActivity] update failed: $e');
    }
  }

  /// Ends the running Live Activity, optionally showing a final [data] state
  /// briefly before it dismisses.
  Future<void> end([Map<String, String>? data]) async {
    if (!Platform.isIOS) return;
    try {
      await _channel.invokeMethod('end', data);
    } catch (e) {
      AppLogger.d('[LiveActivity] end failed: $e');
    }
  }
}

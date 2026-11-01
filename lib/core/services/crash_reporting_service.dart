import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Crash reporting via Firebase Crashlytics.
///
/// [initialize] must run after `Firebase.initializeApp` and before `runApp`.
/// It routes every uncaught error to Crashlytics:
/// - Flutter framework errors (build/layout/paint) via [FlutterError.onError].
/// - Uncaught async / platform errors via [PlatformDispatcher.onError].
///
/// Collection is disabled in debug builds so local development never pollutes
/// the production dashboard; errors still print to the console as usual.
class CrashReportingService {
  CrashReportingService._();

  static FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  static Future<void> initialize() async {
    await _crashlytics.setCrashlyticsCollectionEnabled(!kDebugMode);

    // `recordFlutterFatalError` also calls `FlutterError.presentError`, so the
    // red-screen / console output in debug is unchanged.
    FlutterError.onError = _crashlytics.recordFlutterFatalError;

    PlatformDispatcher.instance.onError = (error, stack) {
      _crashlytics.recordError(error, stack, fatal: true);
      return true;
    };

    AppLogger.d('[Crashlytics] Initialized (collection: ${!kDebugMode})');
  }

  /// Reports a caught, non-fatal error — e.g. from a `catch` block that
  /// recovers but should still be tracked.
  static Future<void> recordError(
    Object error,
    StackTrace? stack, {
    String? reason,
  }) =>
      _crashlytics.recordError(error, stack, reason: reason);

  /// Adds a breadcrumb attached to the next crash report.
  static Future<void> log(String message) => _crashlytics.log(message);

  /// Associates subsequent reports with a user. Pass `null` (or an empty
  /// string) on logout. Use an opaque id, never PII such as phone or email.
  static Future<void> setUserId(String? userId) =>
      _crashlytics.setUserIdentifier(userId ?? '');
}

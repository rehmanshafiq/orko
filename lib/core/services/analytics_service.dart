import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';

/// Analytics service abstraction.
///
/// Provider-agnostic seam over the analytics backend (currently Firebase).
/// Injected via `get_it`; call sites depend on this class, not on
/// `FirebaseAnalytics` directly, so the provider can be swapped without
/// touching feature code.
class AnalyticsService {
  AnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ?? FirebaseAnalytics.instance;

  final FirebaseAnalytics _analytics;

  /// The observer used to emit automatic `screen_view` events on route changes.
  /// Attach to the `go_router` `observers` list.
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Logs a custom event. `null` parameter values are dropped, and values are
  /// coerced to the `String`/`num` types GA4 accepts so a stray `bool`/enum
  /// never silently drops the whole event.
  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    final sanitized = _sanitize(parameters);
    AppLogger.d('[Analytics] $name: $sanitized');
    _analytics.logEvent(
      name: name,
      parameters: sanitized.isEmpty ? null : sanitized,
    );
  }

  void setUserId(String? userId) {
    AppLogger.d('[Analytics] Set user ID: $userId');
    _analytics.setUserId(id: userId);
  }

  void setUserProperty({required String name, required String? value}) {
    AppLogger.d('[Analytics] Set property: $name = $value');
    _analytics.setUserProperty(name: name, value: value);
  }

  void logScreenView(String screenName) {
    AppLogger.d('[Analytics] Screen: $screenName');
    _analytics.logScreenView(screenName: screenName);
  }

  /// GA4 accepts only `String` and `num` parameter values. Coerce everything
  /// else (booleans → "true"/"false", enums/other → `toString()`) and drop
  /// `null`s so a single bad value can't cause the whole event to be rejected.
  Map<String, Object> _sanitize(Map<String, dynamic>? parameters) {
    final result = <String, Object>{};
    if (parameters == null) return result;
    parameters.forEach((key, value) {
      if (value == null) return;
      if (value is num || value is String) {
        result[key] = value;
      } else if (value is bool) {
        result[key] = value.toString();
      } else {
        result[key] = value.toString();
      }
    });
    return result;
  }
}

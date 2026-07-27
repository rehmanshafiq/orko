import 'package:orko_hubco/core/utils/app_logger.dart';

/// Analytics service abstraction.
/// Easily swap providers (Firebase, Amplitude, Mixpanel, etc).
class AnalyticsService {
  // TODO: Initialize your analytics provider here.

  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    AppLogger.d('[Analytics] $name: $parameters');
    // FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  void setUserId(String userId) {
    AppLogger.d('[Analytics] Set user ID: $userId');
  }

  void setUserProperty({required String name, required String value}) {
    AppLogger.d('[Analytics] Set property: $name = $value');
  }

  void logScreenView(String screenName) {
    AppLogger.d('[Analytics] Screen: $screenName');
  }
}

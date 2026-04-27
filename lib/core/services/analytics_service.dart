import 'dart:developer';

/// Analytics service abstraction.
/// Easily swap providers (Firebase, Amplitude, Mixpanel, etc).
class AnalyticsService {
  // TODO: Initialize your analytics provider here.

  void logEvent(String name, {Map<String, dynamic>? parameters}) {
    log('[Analytics] $name: $parameters');
    // FirebaseAnalytics.instance.logEvent(name: name, parameters: parameters);
  }

  void setUserId(String userId) {
    log('[Analytics] Set user ID: $userId');
  }

  void setUserProperty({required String name, required String value}) {
    log('[Analytics] Set property: $name = $value');
  }

  void logScreenView(String screenName) {
    log('[Analytics] Screen: $screenName');
  }
}

/// Keys used for local storage (GetStorage).
class StorageConstants {
  StorageConstants._();

  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String cachedUser = 'cached_user';
  static const String isLoggedIn = 'is_logged_in';
  static const String isGuest = 'is_guest';
  static const String onboardingComplete = 'onboarding_complete';
  static const String themeMode = 'theme_mode';
  static const String appInstallTime = 'app_install_time';
  static const String languageCode = 'language_code';
  static const String vehicles = 'vehicles';
  static const String vehiclesInitialized = 'vehicles_initialized';
  static const String remoteConfigCache = 'remote_config_cache';
  static const String recentStationSearches = 'recent_station_searches';

  /// Latest FCM device token, persisted so the login request can attach it.
  static const String fcmToken = 'fcm_token';

  /// The FCM token most recently registered with the backend (dedupes the
  /// `device-token` upsert so we don't re-POST an unchanged token).
  static const String fcmTokenRegistered = 'fcm_token_registered';

  /// Id of the charging session last seen active on the live-session endpoint.
  /// Persisted so the post-session summary can still be shown when the session
  /// ends while the app is killed; cleared once the summary is dismissed.
  static const String activeChargeSessionId = 'active_charge_session_id';
}

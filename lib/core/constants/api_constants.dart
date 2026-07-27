/// API-related constants.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://staging-python.orkofleet.com/'; // 'https://apis-py.orkofleet.com/'

  /// Google Places (Autocomplete + Details) API key.
  ///
  /// SECURITY: the key is NOT hardcoded here. It is resolved at runtime from
  /// Firebase Remote Config (primary) with this compile-time value as a last
  /// resort — injected only via `--dart-define=GOOGLE_PLACES_API_KEY=...` at
  /// build time, so no key lives in version control. Default is empty.
  ///
  /// NOTE: a Google Maps/Places key shipped in any mobile client is inherently
  /// extractable. The real protection is an Application restriction (Android
  /// package + SHA-1, iOS bundle id) plus an API restriction (Places only) on
  /// the key in the Google Cloud console. The previously committed key MUST be
  /// rotated there, since it is exposed in git history.
  static const String googlePlacesApiKey =
      String.fromEnvironment('GOOGLE_PLACES_API_KEY');
}

/// API-related constants.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://staging-python.orkofleet.com/'; // 'https://apis-py.orkofleet.com/'

  /// Google Places (Autocomplete + Details) API key.
  ///
  /// Resolution order (see [GooglePlacesService]):
  ///   1. Firebase Remote Config (primary; delivered OTA, never committed).
  ///   2. This compile-time fallback — the `MAPS_API_KEY` dart-define, sourced
  ///      from the git-ignored `android/local.properties` at build time (use
  ///      `scripts/flutter_maps.sh`, which extracts it and passes
  ///      `--dart-define=MAPS_API_KEY=...`). Default is empty when not provided.
  ///
  /// No key is stored in version control. NOTE: a Google Maps/Places key
  /// shipped in any mobile client is inherently extractable — the real
  /// protection is an Application restriction (Android package + release SHA-1,
  /// iOS bundle id) plus an API restriction (Places/Maps only) on the key in
  /// the Google Cloud console. The previously committed key MUST be rotated
  /// there, since it remains exposed in git history.
  static const String googlePlacesApiKey =
      String.fromEnvironment('MAPS_API_KEY');
}

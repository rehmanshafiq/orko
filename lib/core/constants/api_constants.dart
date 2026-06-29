/// API-related constants.
class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://postman-echo.com';

  // Auth endpoints (Postman echo reflects your POST payload)
  static const String login = '/post';
  static const String register = '/post';
  static const String refreshToken = '/post';
  static const String logout = '/post';

  // Profile endpoints
  static const String profile = '/get';
  static const String updateProfile = '/post';

  // Map endpoints
  static const String hubcoLocations =
      'https://staging-python.orkofleet.com/portal/api/v1/charging-station/hubco-locations';

  /// Google Places (Autocomplete + Details) API key. Shares the project's
  /// Google Maps key — ensure the Places API is enabled for it in the console.
  static const String googlePlacesApiKey =
      'AIzaSyDdfWz53rd1de4VDmBWJblRgFrL8Hrfd-Q';
}

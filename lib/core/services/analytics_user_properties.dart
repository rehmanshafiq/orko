import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';

/// Sets the Firebase Analytics user id and the segmentation user properties at
/// the auth boundary. Centralised so the property names and value formats stay
/// consistent everywhere they're set (login, Google, OTP, cold start, guest,
/// logout, vehicle changes).
///
/// Properties:
/// * `user_type`   — `authenticated` / `guest`
/// * `has_vehicle` — `true` / `false`
class AnalyticsUserProperties {
  AnalyticsUserProperties(this._analytics);

  final AnalyticsService _analytics;

  static const String _userType = 'user_type';
  static const String _hasVehicle = 'has_vehicle';

  /// Full identity for an authenticated user. `has_vehicle` is seeded from the
  /// cached vehicle lists on [user]; the authoritative value is refreshed via
  /// [setHasVehicle] whenever the live vehicle list loads or changes.
  void setAuthenticated(UserEntity user) {
    _analytics.setUserId(user.id.trim().isEmpty ? null : user.id.trim());
    _analytics.setUserProperty(name: _userType, value: 'authenticated');
    _analytics.setUserProperty(
      name: _hasVehicle,
      value: _boolStr(_userHasVehicle(user)),
    );
  }

  /// Minimal identity when we know the session is authenticated but the full
  /// [UserEntity] isn't available yet (e.g. right after OTP verification). Only
  /// the critical `user_type` is set; the rest fill in once the user loads.
  void setAuthenticatedType() {
    _analytics.setUserProperty(name: _userType, value: 'authenticated');
  }

  /// Guest session: no user id and never a vehicle.
  void setGuest() {
    _analytics.setUserId(null);
    _analytics.setUserProperty(name: _userType, value: 'guest');
    _analytics.setUserProperty(name: _hasVehicle, value: 'false');
  }

  /// Logout: drop the id and clear every identity property (a null value clears
  /// the property in GA4).
  void clear() {
    _analytics.setUserId(null);
    _analytics.setUserProperty(name: _userType, value: null);
    _analytics.setUserProperty(name: _hasVehicle, value: null);
  }

  /// Keeps `has_vehicle` in sync with the authoritative vehicle list (guests are
  /// always `false`).
  void setHasVehicle(bool hasVehicle) {
    _analytics.setUserProperty(name: _hasVehicle, value: _boolStr(hasVehicle));
  }

  static String _boolStr(bool value) => value ? 'true' : 'false';

  static bool _userHasVehicle(UserEntity user) =>
      user.vehicles.isNotEmpty || user.csmsVehicles.isNotEmpty;
}

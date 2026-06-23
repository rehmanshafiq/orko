import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';

/// Maps the preferences shape:
/// ```json
/// {
///   "charging_updates": true,
///   "booking_reminders": true,
///   "promotional_offers": true,
///   "app_updates": true
/// }
/// ```
class NotificationPreferencesModel extends NotificationPreferencesEntity {
  const NotificationPreferencesModel({
    required super.chargingUpdates,
    required super.bookingReminders,
    required super.promotionalOffers,
    required super.appUpdates,
  });

  /// Parses the response. Missing fields default to `true` to mirror the
  /// backend's "new users get all toggles on" behaviour.
  factory NotificationPreferencesModel.fromJson(Map<String, dynamic> json) {
    // Tolerate a `body`-wrapped envelope.
    final data = (json['body'] is Map)
        ? Map<String, dynamic>.from(json['body'] as Map)
        : json;
    return NotificationPreferencesModel(
      chargingUpdates: _asBool(data['charging_updates']),
      bookingReminders: _asBool(data['booking_reminders']),
      promotionalOffers: _asBool(data['promotional_offers']),
      appUpdates: _asBool(data['app_updates']),
    );
  }

  static bool _asBool(dynamic value, {bool fallback = true}) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      if (v == 'true' || v == '1') return true;
      if (v == 'false' || v == '0') return false;
    }
    return fallback;
  }
}

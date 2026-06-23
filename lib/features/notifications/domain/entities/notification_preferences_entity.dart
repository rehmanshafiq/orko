import 'package:equatable/equatable.dart';

/// The four notification preference toggles from
/// `GET/PATCH /api/v1/notifications/preferences/`.
///
/// New users default every toggle to `true` server-side. `appUpdates` exists
/// but currently has no trigger (reserved for future use).
class NotificationPreferencesEntity extends Equatable {
  const NotificationPreferencesEntity({
    required this.chargingUpdates,
    required this.bookingReminders,
    required this.promotionalOffers,
    required this.appUpdates,
  });

  final bool chargingUpdates;
  final bool bookingReminders;
  final bool promotionalOffers;
  final bool appUpdates;

  /// Sensible default (all on) used as an optimistic starting point.
  const NotificationPreferencesEntity.allOn()
      : chargingUpdates = true,
        bookingReminders = true,
        promotionalOffers = true,
        appUpdates = true;

  bool valueOf(NotificationPreferenceKey key) {
    switch (key) {
      case NotificationPreferenceKey.chargingUpdates:
        return chargingUpdates;
      case NotificationPreferenceKey.bookingReminders:
        return bookingReminders;
      case NotificationPreferenceKey.promotionalOffers:
        return promotionalOffers;
      case NotificationPreferenceKey.appUpdates:
        return appUpdates;
    }
  }

  NotificationPreferencesEntity copyWithKey(
    NotificationPreferenceKey key,
    bool value,
  ) {
    return NotificationPreferencesEntity(
      chargingUpdates: key == NotificationPreferenceKey.chargingUpdates
          ? value
          : chargingUpdates,
      bookingReminders: key == NotificationPreferenceKey.bookingReminders
          ? value
          : bookingReminders,
      promotionalOffers: key == NotificationPreferenceKey.promotionalOffers
          ? value
          : promotionalOffers,
      appUpdates:
          key == NotificationPreferenceKey.appUpdates ? value : appUpdates,
    );
  }

  @override
  List<Object?> get props =>
      [chargingUpdates, bookingReminders, promotionalOffers, appUpdates];
}

/// A preference toggle, with its exact API field name.
enum NotificationPreferenceKey {
  chargingUpdates('charging_updates'),
  bookingReminders('booking_reminders'),
  promotionalOffers('promotional_offers'),
  appUpdates('app_updates');

  const NotificationPreferenceKey(this.apiKey);

  final String apiKey;
}

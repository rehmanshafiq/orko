import 'package:orko_hubco/features/notifications/data/models/notification_page_model.dart';
import 'package:orko_hubco/features/notifications/data/models/notification_preferences_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPageModel> getNotifications({
    required int page,
    required int pageSize,
  });

  Future<int> getUnreadCount();

  Future<bool> markRead(int id);

  Future<bool> markAllRead();

  /// Permanently deletes every notification for the user.
  Future<bool> clearAll();

  Future<NotificationPreferencesModel> getPreferences();

  Future<NotificationPreferencesModel> updatePreferences(
    Map<String, bool> changes,
  );

  /// Upserts the FCM device [token] for the authenticated user.
  Future<bool> registerDeviceToken(String token);

  /// Clears the authenticated user's FCM device token (called on logout).
  Future<bool> deleteDeviceToken();
}

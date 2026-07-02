import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_page_entity.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';

abstract class NotificationRepository {
  /// Paginated list, newest first.
  Future<Either<Failure, NotificationPageEntity>> getNotifications({
    required int page,
    required int pageSize,
  });

  /// Unread count for the badge.
  Future<Either<Failure, int>> getUnreadCount();

  /// Marks a single notification read.
  Future<Either<Failure, bool>> markRead(int id);

  /// Marks every notification read.
  Future<Either<Failure, bool>> markAllRead();

  /// Permanently deletes every notification for the user.
  Future<Either<Failure, bool>> clearAll();

  /// Current notification preference toggle states.
  Future<Either<Failure, NotificationPreferencesEntity>> getPreferences();

  /// Updates the given preference field(s); [changes] maps API field names to
  /// their new values (send only what changed). Returns the full updated set.
  Future<Either<Failure, NotificationPreferencesEntity>> updatePreferences(
    Map<String, bool> changes,
  );

  /// Upserts the FCM device token (call on token refresh).
  Future<Either<Failure, bool>> registerDeviceToken(String token);

  /// Clears the FCM device token (call on logout).
  Future<Either<Failure, bool>> deleteDeviceToken();
}

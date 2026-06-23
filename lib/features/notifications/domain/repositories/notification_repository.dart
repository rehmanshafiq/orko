import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_page_entity.dart';

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
}

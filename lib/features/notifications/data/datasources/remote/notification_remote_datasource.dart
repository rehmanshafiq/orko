import 'package:orko_hubco/features/notifications/data/models/notification_page_model.dart';

abstract class NotificationRemoteDataSource {
  Future<NotificationPageModel> getNotifications({
    required int page,
    required int pageSize,
  });

  Future<int> getUnreadCount();

  Future<bool> markRead(int id);

  Future<bool> markAllRead();
}

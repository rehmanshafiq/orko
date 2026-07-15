import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_notifications_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/get_unread_count_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/clear_notifications_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/mark_all_notifications_read_usecase.dart';
import 'package:orko_hubco/features/notifications/domain/usecases/mark_notification_read_usecase.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notifications_state.dart';

class NotificationsCubit extends Cubit<NotificationsState> {
  NotificationsCubit({
    required GetNotificationsUseCase getNotifications,
    required GetUnreadCountUseCase getUnreadCount,
    required MarkNotificationReadUseCase markRead,
    required MarkAllNotificationsReadUseCase markAllRead,
    required ClearNotificationsUseCase clearAll,
  })  : _getNotifications = getNotifications,
        _getUnreadCount = getUnreadCount,
        _markRead = markRead,
        _markAllRead = markAllRead,
        _clearAll = clearAll,
        super(const NotificationsState());

  final GetNotificationsUseCase _getNotifications;
  final GetUnreadCountUseCase _getUnreadCount;
  final MarkNotificationReadUseCase _markRead;
  final MarkAllNotificationsReadUseCase _markAllRead;
  final ClearNotificationsUseCase _clearAll;

  static const int _pageSize = 20;

  /// First load (and full reload after a fatal error). Fetches page 1 and the
  /// unread count together.
  Future<void> loadInitial() async {
    if (state.status == NotificationsStatus.loading) return;
    emit(state.copyWith(
      status: NotificationsStatus.loading,
      clearErrorMessage: true,
      clearActionError: true,
    ));

    final result = await _getNotifications(
      const GetNotificationsParams(page: 1, pageSize: _pageSize),
    );
    if (isClosed) return; // Screen closed mid-request — nothing to update.

    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: NotificationsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (pageData) async {
        emit(state.copyWith(
          status: NotificationsStatus.success,
          notifications: pageData.items,
          page: 1,
          hasMore: pageData.hasMore,
          clearErrorMessage: true,
        ));
        await _refreshUnreadCount();
      },
    );
  }

  /// Pull-to-refresh. Keeps the existing list on screen until the new page 1
  /// resolves; on failure the old list stays and a transient error is surfaced.
  Future<void> refresh() async {
    if (state.isRefreshing) return;
    emit(state.copyWith(isRefreshing: true, clearActionError: true));

    final result = await _getNotifications(
      const GetNotificationsParams(page: 1, pageSize: _pageSize),
    );
    // Pull-to-refresh can outlive the screen (the RefreshIndicator future
    // resolves after pop); bail before emitting on a closed cubit.
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(state.copyWith(isRefreshing: false, actionError: failure.message));
      },
      (pageData) async {
        emit(state.copyWith(
          status: NotificationsStatus.success,
          notifications: pageData.items,
          page: 1,
          hasMore: pageData.hasMore,
          isRefreshing: false,
          clearErrorMessage: true,
        ));
        await _refreshUnreadCount();
      },
    );
  }

  /// Loads the next page and appends it (de-duplicated by id).
  Future<void> loadMore() async {
    if (state.status != NotificationsStatus.success) return;
    if (!state.hasMore || state.isLoadingMore || state.isRefreshing) return;

    emit(state.copyWith(isLoadingMore: true, clearActionError: true));
    final nextPage = state.page + 1;

    final result = await _getNotifications(
      GetNotificationsParams(page: nextPage, pageSize: _pageSize),
    );
    if (isClosed) return;

    result.fold(
      (failure) {
        emit(state.copyWith(isLoadingMore: false, actionError: failure.message));
      },
      (pageData) {
        final existingIds = state.notifications.map((n) => n.id).toSet();
        final fresh =
            pageData.items.where((n) => !existingIds.contains(n.id)).toList();
        emit(state.copyWith(
          notifications: [...state.notifications, ...fresh],
          page: nextPage,
          hasMore: pageData.hasMore,
          isLoadingMore: false,
        ));
      },
    );
  }

  /// Optimistically marks one notification read; reverts on failure.
  Future<void> markAsRead(int id) async {
    final index = state.notifications.indexWhere((n) => n.id == id);
    if (index < 0) return;
    if (state.notifications[index].isRead) return; // Already read — no-op.

    final previous = state.notifications;
    final previousUnread = state.unreadCount;

    final updated = [...previous];
    updated[index] = updated[index].copyWith(isRead: true);
    emit(state.copyWith(
      notifications: updated,
      unreadCount: previousUnread > 0 ? previousUnread - 1 : 0,
    ));

    final result = await _markRead(id);
    if (isClosed) return;
    result.fold(
      (failure) {
        // Revert the optimistic update.
        emit(state.copyWith(
          notifications: previous,
          unreadCount: previousUnread,
          actionError: failure.message,
        ));
      },
      (_) {},
    );
  }

  /// Optimistically marks every notification read; reverts on failure.
  Future<void> markAllAsRead() async {
    if (state.markingAll) return;
    final hasUnread =
        state.unreadCount > 0 || state.notifications.any((n) => !n.isRead);
    if (!hasUnread) return;

    final previous = state.notifications;
    final previousUnread = state.unreadCount;

    final allRead =
        previous.map((n) => n.isRead ? n : n.copyWith(isRead: true)).toList();
    emit(state.copyWith(
      notifications: allRead,
      unreadCount: 0,
      markingAll: true,
    ));

    final result = await _markAllRead(const NoParams());
    if (isClosed) return;
    result.fold(
      (failure) {
        emit(state.copyWith(
          notifications: previous,
          unreadCount: previousUnread,
          markingAll: false,
          actionError: failure.message,
        ));
      },
      (_) {
        emit(state.copyWith(markingAll: false));
      },
    );
  }

  /// Permanently deletes every notification. Non-optimistic: the list stays on
  /// screen (with the button spinner) until the server confirms, then it's
  /// emptied. Returns `true` on success so the caller can show a confirmation.
  Future<bool> clearAllNotifications() async {
    if (state.clearing) return false;
    if (state.notifications.isEmpty) return false;

    emit(state.copyWith(clearing: true, clearActionError: true));

    final result = await _clearAll(const NoParams());
    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(state.copyWith(clearing: false, actionError: failure.message));
        return false;
      },
      (_) {
        emit(state.copyWith(
          status: NotificationsStatus.success,
          notifications: const [],
          unreadCount: 0,
          page: 1,
          hasMore: false,
          clearing: false,
        ));
        // Best-effort: also reset the server-side unread count so badges
        // elsewhere don't keep showing stale unread notifications.
        _markAllRead(const NoParams());
        return true;
      },
    );
  }

  /// Best-effort unread-count sync (failure leaves the prior value intact).
  Future<void> _refreshUnreadCount() async {
    final result = await _getUnreadCount(const NoParams());
    if (isClosed) return;
    result.fold(
      (_) {},
      (count) => emit(state.copyWith(unreadCount: count)),
    );
  }
}

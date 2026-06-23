import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_entity.dart';

enum NotificationsStatus { initial, loading, success, failure }

class NotificationsState extends Equatable {
  const NotificationsState({
    this.status = NotificationsStatus.initial,
    this.notifications = const [],
    this.unreadCount = 0,
    this.page = 1,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.isRefreshing = false,
    this.markingAll = false,
    this.errorMessage,
    this.actionError,
  });

  /// Status of the first (initial) page load.
  final NotificationsStatus status;
  final List<NotificationEntity> notifications;
  final int unreadCount;

  /// Highest page number successfully loaded.
  final int page;
  final bool hasMore;

  /// A subsequent page is being fetched (bottom spinner).
  final bool isLoadingMore;

  /// Pull-to-refresh is in flight (existing list stays visible).
  final bool isRefreshing;

  /// Mark-all-read is in flight.
  final bool markingAll;

  /// Fatal error for the initial load (drives the full-screen error state).
  final String? errorMessage;

  /// Transient error for pagination / mark actions (drives a one-shot snackbar).
  final String? actionError;

  bool get isEmpty =>
      status == NotificationsStatus.success && notifications.isEmpty;

  NotificationsState copyWith({
    NotificationsStatus? status,
    List<NotificationEntity>? notifications,
    int? unreadCount,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
    bool? markingAll,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? actionError,
    bool clearActionError = false,
  }) {
    return NotificationsState(
      status: status ?? this.status,
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      markingAll: markingAll ?? this.markingAll,
      errorMessage: clearErrorMessage ? null : (errorMessage ?? this.errorMessage),
      actionError: clearActionError ? null : (actionError ?? this.actionError),
    );
  }

  @override
  List<Object?> get props => [
        status,
        notifications,
        unreadCount,
        page,
        hasMore,
        isLoadingMore,
        isRefreshing,
        markingAll,
        errorMessage,
        actionError,
      ];
}

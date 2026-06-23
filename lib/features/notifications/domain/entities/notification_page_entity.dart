import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_entity.dart';

/// One page of notifications plus the cursor needed to fetch the next page.
class NotificationPageEntity extends Equatable {
  const NotificationPageEntity({
    required this.items,
    required this.hasMore,
    this.totalCount,
  });

  final List<NotificationEntity> items;

  /// True when at least one more page exists after this one.
  final bool hasMore;

  /// Total notifications across all pages, when the backend reports it.
  final int? totalCount;

  @override
  List<Object?> get props => [items, hasMore, totalCount];
}

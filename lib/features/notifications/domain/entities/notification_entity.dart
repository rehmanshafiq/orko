import 'package:equatable/equatable.dart';

/// A single in-app notification from `GET /api/v1/notifications/`.
class NotificationEntity extends Equatable {
  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    this.sentAt,
  });

  final int id;
  final String title;
  final String body;
  final bool isRead;

  /// Epoch seconds. May be null if the backend hasn't dispatched it yet.
  final int? sentAt;

  /// Epoch seconds.
  final int createdAt;

  /// The timestamp to surface in the UI (prefers [sentAt], falls back to
  /// [createdAt]).
  int get displayTimestamp => sentAt ?? createdAt;

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      isRead: isRead ?? this.isRead,
      sentAt: sentAt,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, body, isRead, sentAt, createdAt];
}

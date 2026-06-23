import 'package:orko_hubco/features/notifications/domain/entities/notification_entity.dart';

/// Maps the notification object shape:
/// ```json
/// {
///   "id": 1,
///   "title": "Booking Approved",
///   "body": "Your booking has been approved.",
///   "is_read": false,
///   "sent_at": 1718000000,
///   "created_at": 1718000000
/// }
/// ```
class NotificationModel extends NotificationEntity {
  const NotificationModel({
    required super.id,
    required super.title,
    required super.body,
    required super.isRead,
    required super.createdAt,
    super.sentAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _asInt(json['id']) ?? 0,
      title: (json['title'] as String?)?.trim() ?? '',
      body: (json['body'] as String?)?.trim() ?? '',
      isRead: _asBool(json['is_read']),
      sentAt: _asInt(json['sent_at']),
      createdAt: _asInt(json['created_at']) ?? _asInt(json['sent_at']) ?? 0,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final v = value.toLowerCase().trim();
      return v == 'true' || v == '1';
    }
    return false;
  }
}

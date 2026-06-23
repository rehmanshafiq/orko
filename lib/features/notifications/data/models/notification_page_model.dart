import 'package:orko_hubco/features/notifications/data/models/notification_model.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_page_entity.dart';

/// Parses a notifications page from either a DRF paginated envelope
/// (`{count, next, previous, results}`) or a bare list. [requestedPageSize]
/// is used to infer `hasMore` when the backend omits a `next` cursor.
class NotificationPageModel extends NotificationPageEntity {
  const NotificationPageModel({
    required super.items,
    required super.hasMore,
    super.totalCount,
  });

  factory NotificationPageModel.fromResponse(
    dynamic data, {
    required int requestedPageSize,
  }) {
    // Unwrap a `body` envelope if the backend wraps the payload.
    var payload = data;
    if (payload is Map && payload['body'] != null) {
      payload = payload['body'];
    }

    List rawList;
    bool hasMore;
    int? totalCount;

    if (payload is Map) {
      final results = payload['results'];
      rawList = results is List ? results : const [];
      final next = payload['next'];
      totalCount = _asInt(payload['count']);
      // Prefer the explicit cursor; otherwise fall back to page-size heuristic.
      hasMore = next != null && next.toString().isNotEmpty;
      if (payload['next'] == null && !payload.containsKey('next')) {
        hasMore = rawList.length >= requestedPageSize;
      }
    } else if (payload is List) {
      rawList = payload;
      hasMore = rawList.length >= requestedPageSize;
    } else {
      rawList = const [];
      hasMore = false;
    }

    final items = rawList
        .whereType<Map>()
        .map((e) => NotificationModel.fromJson(Map<String, dynamic>.from(e)))
        .toList(growable: false);

    return NotificationPageModel(
      items: items,
      hasMore: hasMore,
      totalCount: totalCount,
    );
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

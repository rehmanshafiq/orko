import 'package:orko_hubco/features/notifications/data/models/notification_model.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_page_entity.dart';

/// Parses a notifications page from the backend's envelope, where the items live
/// under `body` (a list) while the pagination cursors (`next`,
/// `next_page_number`, `count`) sit at the TOP level alongside `body`:
///
/// ```
/// { status, message, body: [ ... ], next: ".../?page=2", count: 94,
///   next_page_number: 2, previous_page_number: null }
/// ```
///
/// Also tolerates a standard DRF envelope (`{count, next, results}`), a
/// `body`-wrapped DRF envelope, and a bare list. [requestedPageSize] is the
/// last-resort heuristic for `hasMore` when no cursor is present.
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
    List rawList = const [];
    int? totalCount;
    bool? hasMore;

    if (data is Map) {
      final body = data['body'];

      // Items: `body` (this backend), or DRF `results` (possibly nested in
      // `body`).
      if (body is List) {
        rawList = body;
      } else if (body is Map && body['results'] is List) {
        rawList = body['results'] as List;
      } else if (data['results'] is List) {
        rawList = data['results'] as List;
      }

      // Pagination metadata can sit at the top level (this backend, where
      // `body` is the list) or inside a nested DRF envelope.
      final meta = body is Map ? body : data;
      totalCount = _asInt(meta['count']) ?? _asInt(data['count']);
      hasMore = _hasMoreFrom(meta) ?? _hasMoreFrom(data);
    } else if (data is List) {
      rawList = data;
    }

    // Last resort when no cursor is available: a full page implies more.
    hasMore ??= rawList.length >= requestedPageSize;

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

  /// Derives `hasMore` from whichever cursor the [map] carries. Returns null
  /// when the map has no pagination keys, so the caller can fall back.
  static bool? _hasMoreFrom(Map map) {
    // Prefer the explicit page number — it's null on the last page.
    if (map.containsKey('next_page_number')) {
      return map['next_page_number'] != null;
    }
    // DRF cursor URL: a non-empty string means there's another page.
    if (map.containsKey('next')) {
      final next = map['next'];
      return next != null && next.toString().isNotEmpty;
    }
    return null;
  }

  static int? _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

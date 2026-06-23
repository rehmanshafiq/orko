import 'package:orko_hubco/features/search/domain/entities/recent_search_entity.dart';

/// Serialisable form of [RecentSearchEntity] for local storage. Persisted as a
/// JSON object inside the recent-searches array.
class RecentSearchModel extends RecentSearchEntity {
  const RecentSearchModel({
    required super.query,
    required super.searchedAt,
  });

  factory RecentSearchModel.fromEntity(RecentSearchEntity entity) {
    return RecentSearchModel(
      query: entity.query,
      searchedAt: entity.searchedAt,
    );
  }

  /// Parsed defensively — a malformed/legacy entry yields epoch time rather
  /// than throwing, so one bad record can't wipe the whole history.
  factory RecentSearchModel.fromJson(Map<String, dynamic> json) {
    final raw = json['searched_at'];
    return RecentSearchModel(
      query: (json['query'] ?? '').toString(),
      searchedAt: DateTime.tryParse('${raw ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'query': query,
      'searched_at': searchedAt.toIso8601String(),
    };
  }
}

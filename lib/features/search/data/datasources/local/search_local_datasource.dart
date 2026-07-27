import 'dart:convert';
import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/features/search/data/models/recent_search_model.dart';

abstract class SearchLocalDataSource {
  /// Returns persisted recent searches, newest first.
  Future<List<RecentSearchModel>> getRecentSearches();

  /// Records [query] as the most recent search (de-duplicated, capped).
  /// A blank query is ignored.
  Future<List<RecentSearchModel>> addRecentSearch(String query);

  /// Removes the recent search matching [query] (case-insensitive).
  Future<List<RecentSearchModel>> removeRecentSearch(String query);

  /// Clears the entire recent-search history.
  Future<void> clearRecentSearches();
}

class SearchLocalDataSourceImpl implements SearchLocalDataSource {
  final LocalStorageService storageService;

  const SearchLocalDataSourceImpl({required this.storageService});

  /// Most-recent history we keep; older entries are dropped.
  static const int _maxEntries = 10;

  static const String _key = StorageConstants.recentStationSearches;

  @override
  Future<List<RecentSearchModel>> getRecentSearches() async {
    final raw = storageService.read<String>(_key);
    if (raw == null || raw.trim().isEmpty) return const [];
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((e) => RecentSearchModel.fromJson(Map<String, dynamic>.from(e)))
          .where((e) => e.query.trim().isNotEmpty)
          .toList(growable: false);
    } catch (e) {
      // Corrupt payload (e.g. a partial/legacy write) — reset rather than
      // letting one bad record break the screen on every open.
      AppLogger.d('[Search] Failed to decode recent searches, resetting: $e');
      await storageService.remove(_key);
      return const [];
    }
  }

  @override
  Future<List<RecentSearchModel>> addRecentSearch(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getRecentSearches();

    final current = await getRecentSearches();
    final deduped = current
        .where((e) => e.query.toLowerCase() != trimmed.toLowerCase())
        .toList();

    final updated = <RecentSearchModel>[
      RecentSearchModel(query: trimmed, searchedAt: DateTime.now()),
      ...deduped,
    ].take(_maxEntries).toList(growable: false);

    await _persist(updated);
    return updated;
  }

  @override
  Future<List<RecentSearchModel>> removeRecentSearch(String query) async {
    final current = await getRecentSearches();
    final updated = current
        .where((e) => e.query.toLowerCase() != query.trim().toLowerCase())
        .toList(growable: false);
    await _persist(updated);
    return updated;
  }

  @override
  Future<void> clearRecentSearches() => storageService.remove(_key);

  Future<void> _persist(List<RecentSearchModel> searches) {
    final encoded = json.encode(searches.map((e) => e.toJson()).toList());
    return storageService.write(_key, encoded);
  }
}

import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/search/domain/entities/recent_search_entity.dart';
import 'package:orko_hubco/features/search/domain/entities/station_result_entity.dart';

/// Loading lifecycle for an async section of the Search screen.
enum SearchStatus { initial, loading, success, failure }

/// Single immutable state for the Search screen. The screen shows either the
/// idle layout (recent searches + popular stations) when [query] is blank, or
/// search results when the user is typing.
class SearchState extends Equatable {
  const SearchState({
    this.query = '',
    this.recentSearches = const [],
    this.popularStatus = SearchStatus.initial,
    this.popularStations = const [],
    this.popularError = '',
    this.resultsStatus = SearchStatus.initial,
    this.results = const [],
    this.resultsError = '',
  });

  /// The current (trimmed) query. Blank means the idle layout is shown.
  final String query;

  final List<RecentSearchEntity> recentSearches;

  final SearchStatus popularStatus;
  final List<StationResultEntity> popularStations;
  final String popularError;

  final SearchStatus resultsStatus;
  final List<StationResultEntity> results;
  final String resultsError;

  bool get isSearching => query.trim().isNotEmpty;

  SearchState copyWith({
    String? query,
    List<RecentSearchEntity>? recentSearches,
    SearchStatus? popularStatus,
    List<StationResultEntity>? popularStations,
    String? popularError,
    SearchStatus? resultsStatus,
    List<StationResultEntity>? results,
    String? resultsError,
  }) {
    return SearchState(
      query: query ?? this.query,
      recentSearches: recentSearches ?? this.recentSearches,
      popularStatus: popularStatus ?? this.popularStatus,
      popularStations: popularStations ?? this.popularStations,
      popularError: popularError ?? this.popularError,
      resultsStatus: resultsStatus ?? this.resultsStatus,
      results: results ?? this.results,
      resultsError: resultsError ?? this.resultsError,
    );
  }

  @override
  List<Object?> get props => [
        query,
        recentSearches,
        popularStatus,
        popularStations,
        popularError,
        resultsStatus,
        results,
        resultsError,
      ];
}

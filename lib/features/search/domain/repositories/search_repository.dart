import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/domain/entities/recent_search_entity.dart';
import 'package:orko_hubco/features/search/domain/entities/station_result_entity.dart';

abstract class SearchRepository {
  /// Searches charging stations matching [query] around [latitude]/[longitude].
  Future<Either<Failure, List<StationResultEntity>>> searchStations({
    required String query,
    required double latitude,
    required double longitude,
  });

  /// Returns popular charging stations around [latitude]/[longitude].
  Future<Either<Failure, List<StationResultEntity>>> getPopularStations({
    required double latitude,
    required double longitude,
  });

  /// Returns persisted recent searches, newest first.
  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches();

  /// Records [query] as the most recent search and returns the updated list.
  Future<Either<Failure, List<RecentSearchEntity>>> addRecentSearch(
      String query);

  /// Removes [query] from the recent history and returns the updated list.
  Future<Either<Failure, List<RecentSearchEntity>>> removeRecentSearch(
      String query);

  /// Clears the entire recent-search history.
  Future<Either<Failure, void>> clearRecentSearches();
}

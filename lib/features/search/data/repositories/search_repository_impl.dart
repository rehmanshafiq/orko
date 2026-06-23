import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/data/datasources/local/search_local_datasource.dart';
import 'package:orko_hubco/features/search/data/datasources/remote/search_remote_datasource.dart';
import 'package:orko_hubco/features/search/domain/entities/recent_search_entity.dart';
import 'package:orko_hubco/features/search/domain/entities/station_result_entity.dart';
import 'package:orko_hubco/features/search/domain/repositories/search_repository.dart';

class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource remoteDataSource;
  final SearchLocalDataSource localDataSource;

  const SearchRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<StationResultEntity>>> searchStations({
    required String query,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final results = await remoteDataSource.searchStations(
        query: query,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<StationResultEntity>>> getPopularStations({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final results = await remoteDataSource.getPopularStations(
        latitude: latitude,
        longitude: longitude,
      );
      return Right(results);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> getRecentSearches() async {
    try {
      return Right(await localDataSource.getRecentSearches());
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> addRecentSearch(
      String query) async {
    try {
      return Right(await localDataSource.addRecentSearch(query));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<RecentSearchEntity>>> removeRecentSearch(
      String query) async {
    try {
      return Right(await localDataSource.removeRecentSearch(query));
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearRecentSearches() async {
    try {
      await localDataSource.clearRecentSearches();
      return const Right(null);
    } on CacheException catch (e) {
      return Left(CacheFailure(message: e.message));
    } catch (e) {
      return Left(CacheFailure(message: e.toString()));
    }
  }
}

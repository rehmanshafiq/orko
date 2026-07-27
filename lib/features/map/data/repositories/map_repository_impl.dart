import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/data/datasources/local/map_local_datasource.dart';
import 'package:orko_hubco/features/map/data/datasources/remote/map_remote_datasource.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filter_options_entity.dart';
import 'package:orko_hubco/features/map/domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final MapRemoteDataSource remoteDataSource;
  final MapLocalDataSource localDataSource;

  const MapRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<HubcoLocationEntity>>> getNearestStations({
    required double latitude,
    required double longitude,
    double? radius,
    List<String>? connectorTypes,
    List<int>? amenityIds,
    double? minPrice,
    double? maxPrice,
    double? powerOutput,
    String? city,
  }) async {
    // Primary: remote nearest API.
    try {
      final stations = await remoteDataSource.getNearestStations(
        latitude: latitude,
        longitude: longitude,
        radius: radius,
        connectorTypes: connectorTypes,
        amenityIds: amenityIds,
        minPrice: minPrice,
        maxPrice: maxPrice,
        powerOutput: powerOutput,
        city: city,
      );
      return Right(stations);
    } catch (e) {
      AppLogger.d('[Map] Remote nearest failed, falling back to asset: $e');
    }

    // Fallback: bundled asset. (The asset can't honour filters; it's the
    // offline safety net so the map is never empty on a transient failure.)
    try {
      final stations = await localDataSource.getHubcoLocations();
      return Right(stations);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, StationFilterOptionsEntity>> getFilterOptions() async {
    try {
      final options = await remoteDataSource.getFilterOptions();
      return Right(options);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

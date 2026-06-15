import 'dart:developer';

import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/data/datasources/local/map_local_datasource.dart';
import 'package:orko_hubco/features/map/data/datasources/remote/map_remote_datasource.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
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
  }) async {
    // Primary: remote nearest API.
    try {
      final stations = await remoteDataSource.getNearestStations(
        latitude: latitude,
        longitude: longitude,
      );
      return Right(stations);
    } catch (e) {
      log('[Map] Remote nearest failed, falling back to asset: $e');
    }

    // Fallback: bundled asset.
    try {
      final stations = await localDataSource.getHubcoLocations();
      return Right(stations);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

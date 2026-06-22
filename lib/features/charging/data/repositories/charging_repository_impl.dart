import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/data/datasources/remote/charging_remote_datasource.dart';
import 'package:orko_hubco/features/charging/domain/entities/charger_compatibility_entity.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';
import 'package:orko_hubco/features/charging/domain/entities/favourite_station_entity.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

class ChargingRepositoryImpl implements ChargingRepository {
  final ChargingRemoteDataSource remoteDataSource;

  const ChargingRepositoryImpl({required this.remoteDataSource});

  @override
  Future<Either<Failure, ChargingStationDetailEntity>> getStationDetail({
    required String stationId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final detail = await remoteDataSource.getStationDetail(
        stationId: stationId,
        latitude: latitude,
        longitude: longitude,
      );
      return Right(detail);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<FavouriteStationEntity>>> getFavourites() async {
    try {
      final favourites = await remoteDataSource.getFavourites();
      return Right(favourites);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> addFavourite(int locationId) async {
    try {
      await remoteDataSource.addFavourite(locationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> removeFavourite(int locationId) async {
    try {
      await remoteDataSource.removeFavourite(locationId);
      return const Right(null);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, ChargerCompatibilityEntity>> checkChargerCompatibility({
    required int csmsVehicleId,
    required String chargePointId,
  }) async {
    try {
      final result = await remoteDataSource.checkChargerCompatibility(
        csmsVehicleId: csmsVehicleId,
        chargePointId: chargePointId,
      );
      return Right(result);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

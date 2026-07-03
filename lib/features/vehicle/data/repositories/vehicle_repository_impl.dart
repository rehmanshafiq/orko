import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/data/datasources/remote/vehicle_remote_datasource.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/created_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_make_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_model_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  final VehicleRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const VehicleRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<VehicleMakeEntity>>> getMakes() {
    return _run(() => remoteDataSource.getMakes());
  }

  @override
  Future<Either<Failure, List<VehicleModelEntity>>> getModels({
    required int makeId,
  }) {
    return _run(() => remoteDataSource.getModels(makeId: makeId));
  }

  @override
  Future<Either<Failure, CreatedVehicleEntity>> addVehicle({
    required int mdMake,
    required int mdModel,
    required String year,
    String? vehicleRfid,
  }) {
    return _run(
      () => remoteDataSource.addVehicle(
        mdMake: mdMake,
        mdModel: mdModel,
        year: year,
        vehicleRfid: vehicleRfid,
      ),
    );
  }

  @override
  Future<Either<Failure, List<UserVehicleEntity>>> getUserVehicles() {
    return _run(() => remoteDataSource.getUserVehicles());
  }

  @override
  Future<Either<Failure, void>> deleteVehicle({required int id}) {
    return _run(() => remoteDataSource.deleteVehicle(id: id));
  }

  @override
  Future<Either<Failure, VehicleMakeEntity>> createCustomMake({
    required String name,
  }) {
    return _run(() => remoteDataSource.createCustomMake(name: name));
  }

  @override
  Future<Either<Failure, VehicleModelEntity>> createCustomModel({
    required int mdMake,
    required String name,
    required String connectorType,
    required double batteryCapacity,
    required int mileage,
  }) {
    return _run(
      () => remoteDataSource.createCustomModel(
        mdMake: mdMake,
        name: name,
        connectorType: connectorType,
        batteryCapacity: batteryCapacity,
        mileage: mileage,
      ),
    );
  }

  /// Shared connectivity guard + exception→failure mapping for every call.
  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      return Right(await action());
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/created_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_make_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_model_entity.dart';

abstract class VehicleRepository {
  /// `GET /vehicle/makes/` — car brands.
  Future<Either<Failure, List<VehicleMakeEntity>>> getMakes();

  /// `GET /vehicle/models/?md_make__id=<makeId>` — models for a make.
  Future<Either<Failure, List<VehicleModelEntity>>> getModels({
    required int makeId,
  });

  /// `POST /vehicle/add-vehicle/` — creates a vehicle for the user.
  Future<Either<Failure, CreatedVehicleEntity>> addVehicle({
    required int mdMake,
    required int mdModel,
    required String year,
    String? vehicleRfid,
  });

  /// `GET /vehicle/user-vehicle/` — the logged-in user's vehicles.
  Future<Either<Failure, List<UserVehicleEntity>>> getUserVehicles();

  /// `DELETE /vehicle/add-vehicle/` — soft-deletes the vehicle [id].
  Future<Either<Failure, void>> deleteVehicle({required int id});

  /// `POST /vehicle/custom-make/` — creates a custom make; returns it.
  Future<Either<Failure, VehicleMakeEntity>> createCustomMake({
    required String name,
  });

  /// `POST /vehicle/custom-model/` — creates a custom model; returns it.
  Future<Either<Failure, VehicleModelEntity>> createCustomModel({
    required int mdMake,
    required String name,
    required String connectorType,
    required double batteryCapacity,
    required int mileage,
  });
}

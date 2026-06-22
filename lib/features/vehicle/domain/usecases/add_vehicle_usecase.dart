import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/created_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

class AddVehicleUseCase
    implements UseCase<CreatedVehicleEntity, AddVehicleParams> {
  final VehicleRepository repository;

  const AddVehicleUseCase(this.repository);

  @override
  Future<Either<Failure, CreatedVehicleEntity>> call(AddVehicleParams params) {
    return repository.addVehicle(
      mdMake: params.mdMake,
      mdModel: params.mdModel,
      year: params.year,
      vehicleRfid: params.vehicleRfid,
    );
  }
}

class AddVehicleParams {
  final int mdMake;
  final int mdModel;
  final String year;
  final String? vehicleRfid;

  const AddVehicleParams({
    required this.mdMake,
    required this.mdModel,
    required this.year,
    this.vehicleRfid,
  });
}

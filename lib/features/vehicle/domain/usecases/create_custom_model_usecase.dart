import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_model_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

/// `POST /vehicle/custom-model/` — creates a custom model under a make.
class CreateCustomModelUseCase
    implements UseCase<VehicleModelEntity, CreateCustomModelParams> {
  const CreateCustomModelUseCase(this._repository);

  final VehicleRepository _repository;

  @override
  Future<Either<Failure, VehicleModelEntity>> call(
    CreateCustomModelParams params,
  ) {
    return _repository.createCustomModel(
      mdMake: params.mdMake,
      name: params.name,
      connectorType: params.connectorType,
      batteryCapacity: params.batteryCapacity,
      mileage: params.mileage,
    );
  }
}

class CreateCustomModelParams {
  const CreateCustomModelParams({
    required this.mdMake,
    required this.name,
    required this.connectorType,
    required this.batteryCapacity,
    required this.mileage,
  });

  final int mdMake;
  final String name;
  final String connectorType;
  final double batteryCapacity;
  final int mileage;
}

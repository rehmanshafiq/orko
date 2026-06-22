import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_model_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

class GetVehicleModelsUseCase
    implements UseCase<List<VehicleModelEntity>, GetVehicleModelsParams> {
  final VehicleRepository repository;

  const GetVehicleModelsUseCase(this.repository);

  @override
  Future<Either<Failure, List<VehicleModelEntity>>> call(
    GetVehicleModelsParams params,
  ) {
    return repository.getModels(makeId: params.makeId);
  }
}

class GetVehicleModelsParams {
  final int makeId;

  const GetVehicleModelsParams({required this.makeId});
}

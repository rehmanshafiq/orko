import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_make_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

/// `POST /vehicle/custom-make/` — creates a user/tenant custom make.
class CreateCustomMakeUseCase implements UseCase<VehicleMakeEntity, String> {
  const CreateCustomMakeUseCase(this._repository);

  final VehicleRepository _repository;

  @override
  Future<Either<Failure, VehicleMakeEntity>> call(String name) {
    return _repository.createCustomMake(name: name);
  }
}

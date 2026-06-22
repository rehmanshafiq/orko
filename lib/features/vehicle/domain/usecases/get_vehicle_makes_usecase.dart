import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_make_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

class GetVehicleMakesUseCase
    implements UseCase<List<VehicleMakeEntity>, NoParams> {
  final VehicleRepository repository;

  const GetVehicleMakesUseCase(this.repository);

  @override
  Future<Either<Failure, List<VehicleMakeEntity>>> call(NoParams params) {
    return repository.getMakes();
  }
}

import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

class GetUserVehiclesUseCase
    implements UseCase<List<UserVehicleEntity>, NoParams> {
  final VehicleRepository repository;

  const GetUserVehiclesUseCase(this.repository);

  @override
  Future<Either<Failure, List<UserVehicleEntity>>> call(NoParams params) {
    return repository.getUserVehicles();
  }
}

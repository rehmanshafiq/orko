import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/repositories/vehicle_repository.dart';

class DeleteVehicleUseCase implements UseCase<void, DeleteVehicleParams> {
  final VehicleRepository repository;

  const DeleteVehicleUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(DeleteVehicleParams params) {
    return repository.deleteVehicle(id: params.id);
  }
}

class DeleteVehicleParams {
  final int id;

  const DeleteVehicleParams({required this.id});
}

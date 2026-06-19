import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

class RemoveFavouriteStationUseCase implements UseCase<void, int> {
  final ChargingRepository repository;

  const RemoveFavouriteStationUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int locationId) {
    return repository.removeFavourite(locationId);
  }
}

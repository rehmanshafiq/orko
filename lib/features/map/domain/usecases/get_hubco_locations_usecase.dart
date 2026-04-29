import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/repositories/map_repository.dart';

class GetHubcoLocationsUseCase
    implements UseCase<List<HubcoLocationEntity>, NoParams> {
  final MapRepository repository;

  const GetHubcoLocationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HubcoLocationEntity>>> call(NoParams params) {
    return repository.getHubcoLocations();
  }
}

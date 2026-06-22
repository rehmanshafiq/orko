import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filter_options_entity.dart';
import 'package:orko_hubco/features/map/domain/repositories/map_repository.dart';

class GetFilterOptionsUseCase
    implements UseCase<StationFilterOptionsEntity, NoParams> {
  final MapRepository repository;

  const GetFilterOptionsUseCase(this.repository);

  @override
  Future<Either<Failure, StationFilterOptionsEntity>> call(NoParams params) {
    return repository.getFilterOptions();
  }
}

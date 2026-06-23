import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';

class SaveTripUseCase implements UseCase<SavedTripEntity, TripPlanParams> {
  const SaveTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, SavedTripEntity>> call(TripPlanParams params) {
    return _repository.saveTrip(params);
  }
}

import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';

/// `PUT /trip-planning/edit-trip/{trip_id}/` — updates a saved trip's inputs
/// and re-runs the server-side planner. Reuses [TripPlanParams] for the body.
class EditTripUseCase implements UseCase<SavedTripEntity, EditTripParams> {
  const EditTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, SavedTripEntity>> call(EditTripParams params) {
    return _repository.editTrip(tripId: params.tripId, params: params.params);
  }
}

class EditTripParams {
  const EditTripParams({required this.tripId, required this.params});

  final int tripId;
  final TripPlanParams params;
}

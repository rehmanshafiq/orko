import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_plan_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';

class PlanTripUseCase implements UseCase<TripPlanEntity, TripPlanParams> {
  const PlanTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, TripPlanEntity>> call(TripPlanParams params) {
    return _repository.planTrip(params);
  }
}

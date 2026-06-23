import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';

class GetSavedTripsUseCase
    implements UseCase<List<SavedTripEntity>, NoParams> {
  const GetSavedTripsUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, List<SavedTripEntity>>> call(NoParams params) {
    return _repository.getSavedTrips();
  }
}

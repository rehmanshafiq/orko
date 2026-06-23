import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';

class GetSavedTripDetailUseCase implements UseCase<SavedTripEntity, int> {
  const GetSavedTripDetailUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, SavedTripEntity>> call(int id) {
    return _repository.getSavedTripDetail(id);
  }
}

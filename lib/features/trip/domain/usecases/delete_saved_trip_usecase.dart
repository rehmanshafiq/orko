import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';

/// `DELETE /trip-planning/trips/<id>/` — deletes a saved trip and returns the
/// backend success message.
class DeleteSavedTripUseCase implements UseCase<String, int> {
  const DeleteSavedTripUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, String>> call(int id) {
    return _repository.deleteSavedTrip(id);
  }
}

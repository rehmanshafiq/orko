import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/place_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';
import 'package:orko_hubco/features/trip/domain/usecases/place_search_params.dart';

/// `GET /cvp/places/details/` — resolves a picked prediction to coordinates.
class GetPlaceDetailsUseCase
    implements UseCase<PlaceLocation, PlaceDetailsParams> {
  const GetPlaceDetailsUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, PlaceLocation>> call(PlaceDetailsParams params) {
    return _repository.getPlaceDetails(params);
  }
}

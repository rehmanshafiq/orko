import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/place_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';
import 'package:orko_hubco/features/trip/domain/usecases/place_search_params.dart';

/// `GET /cvp/places/autocomplete/` — place predictions for the search sheet.
class SearchPlacesUseCase
    implements UseCase<List<PlaceSuggestion>, PlaceAutocompleteParams> {
  const SearchPlacesUseCase(this._repository);

  final TripRepository _repository;

  @override
  Future<Either<Failure, List<PlaceSuggestion>>> call(
    PlaceAutocompleteParams params,
  ) {
    return _repository.searchPlaces(params);
  }
}

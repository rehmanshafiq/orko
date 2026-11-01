import 'package:orko_hubco/features/trip/data/models/place_model.dart';
import 'package:orko_hubco/features/trip/data/models/saved_trip_model.dart';
import 'package:orko_hubco/features/trip/data/models/trip_plan_result_model.dart';
import 'package:orko_hubco/features/trip/domain/usecases/place_search_params.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';

abstract class TripRemoteDataSource {
  Future<TripPlanResultModel> planTrip(TripPlanParams params);

  Future<SavedTripModel> saveTrip(TripPlanParams params);

  Future<List<SavedTripModel>> getSavedTrips();

  Future<SavedTripModel> getSavedTripDetail(int id);

  /// `DELETE /trip-planning/trips/<id>/` — returns the success message.
  Future<String> deleteSavedTrip(int id);

  /// `PUT /trip-planning/edit-trip/<id>/` — returns the recomputed trip.
  Future<SavedTripModel> editTrip({
    required int tripId,
    required TripPlanParams params,
  });

  /// `GET /cvp/places/autocomplete/` — `[]` when nothing matches.
  Future<List<PlaceSuggestionModel>> searchPlaces(
    PlaceAutocompleteParams params,
  );

  /// `GET /cvp/places/details/` — the picked place with coordinates.
  Future<PlaceLocationModel> getPlaceDetails(PlaceDetailsParams params);
}

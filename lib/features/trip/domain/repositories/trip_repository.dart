import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_plan_entity.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';

abstract class TripRepository {
  /// `POST /trip-planning/plan-trip/` — computes the optimised plan (no persist).
  Future<Either<Failure, TripPlanEntity>> planTrip(TripPlanParams params);

  /// `POST /trip-planning/save-trip/` — recomputes server-side and persists.
  Future<Either<Failure, SavedTripEntity>> saveTrip(TripPlanParams params);

  /// `GET /trip-planning/trips/` — the user's saved trips, newest first.
  Future<Either<Failure, List<SavedTripEntity>>> getSavedTrips();

  /// `GET /trip-planning/trips/<id>/` — a single saved trip.
  Future<Either<Failure, SavedTripEntity>> getSavedTripDetail(int id);

  /// `DELETE /trip-planning/trips/<id>/` — deletes a saved trip; returns the
  /// success message.
  Future<Either<Failure, String>> deleteSavedTrip(int id);

  /// `PUT /trip-planning/edit-trip/<id>/` — updates a saved trip's inputs and
  /// returns the freshly recomputed trip.
  Future<Either<Failure, SavedTripEntity>> editTrip({
    required int tripId,
    required TripPlanParams params,
  });
}

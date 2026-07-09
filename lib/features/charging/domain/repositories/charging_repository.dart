import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/entities/charger_compatibility_entity.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';
import 'package:orko_hubco/features/charging/domain/entities/favourite_station_entity.dart';
import 'package:orko_hubco/features/charging/domain/entities/station_reviews_entity.dart';

abstract class ChargingRepository {
  /// Returns the full detail for the charging station identified by [stationId],
  /// resolved relative to [latitude]/[longitude] (used for distance).
  Future<Either<Failure, ChargingStationDetailEntity>> getStationDetail({
    required String stationId,
    required double latitude,
    required double longitude,
  });

  /// Returns the user's favourite charging stations.
  Future<Either<Failure, List<FavouriteStationEntity>>> getFavourites();

  /// Adds the station with [locationId] to the user's favourites.
  Future<Either<Failure, void>> addFavourite(int locationId);

  /// Removes the station with [locationId] from the user's favourites.
  Future<Either<Failure, void>> removeFavourite(int locationId);

  /// Checks whether [csmsVehicleId] is compatible with the charger
  /// [chargePointId].
  Future<Either<Failure, ChargerCompatibilityEntity>> checkChargerCompatibility({
    required int csmsVehicleId,
    required String chargePointId,
  });

  /// Fetches all reviews (plus the rating summary) for [locationId].
  Future<Either<Failure, StationReviewsEntity>> getReviews(int locationId);

  /// Adds the current user's review for [locationId].
  Future<Either<Failure, void>> addReview({
    required int locationId,
    required int rating,
    required String description,
  });

  /// Updates the current user's existing review [reviewId] (only [rating] and
  /// [description] are mutable server-side).
  Future<Either<Failure, void>> updateReview({
    required int reviewId,
    required int rating,
    required String description,
  });

  /// Deletes the current user's review [reviewId].
  Future<Either<Failure, void>> deleteReview(int reviewId);
}

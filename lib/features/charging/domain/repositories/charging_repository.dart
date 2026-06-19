import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';
import 'package:orko_hubco/features/charging/domain/entities/favourite_station_entity.dart';

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
}

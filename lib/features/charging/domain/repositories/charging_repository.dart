import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';

abstract class ChargingRepository {
  /// Returns the full detail for the charging station identified by [stationId],
  /// resolved relative to [latitude]/[longitude] (used for distance).
  Future<Either<Failure, ChargingStationDetailEntity>> getStationDetail({
    required String stationId,
    required double latitude,
    required double longitude,
  });
}

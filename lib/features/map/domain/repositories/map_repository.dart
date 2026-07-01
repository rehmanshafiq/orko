import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filter_options_entity.dart';

abstract class MapRepository {
  /// Returns nearest charging stations for the given coordinates, optionally
  /// narrowed by the filter params. Falls back to the bundled asset when the
  /// remote request fails.
  Future<Either<Failure, List<HubcoLocationEntity>>> getNearestStations({
    required double latitude,
    required double longitude,
    double? radius,
    List<String>? connectorTypes,
    List<int>? amenityIds,
    double? minPrice,
    double? maxPrice,
    double? powerOutput,
    String? city,
  });

  /// Returns the available filter options (connector types + amenities).
  Future<Either<Failure, StationFilterOptionsEntity>> getFilterOptions();
}

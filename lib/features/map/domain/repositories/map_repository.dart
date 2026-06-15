import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

abstract class MapRepository {
  /// Returns nearest charging stations for the given coordinates. Falls back to
  /// the bundled asset when the remote request fails.
  Future<Either<Failure, List<HubcoLocationEntity>>> getNearestStations({
    required double latitude,
    required double longitude,
  });
}

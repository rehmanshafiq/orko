import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

abstract class MapRepository {
  Future<Either<Failure, List<HubcoLocationEntity>>> getHubcoLocations();
}

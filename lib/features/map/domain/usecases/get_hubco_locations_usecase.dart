import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/repositories/map_repository.dart';

class GetHubcoLocationsUseCase
    implements UseCase<List<HubcoLocationEntity>, NearestStationsParams> {
  final MapRepository repository;

  const GetHubcoLocationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<HubcoLocationEntity>>> call(
    NearestStationsParams params,
  ) {
    return repository.getNearestStations(
      latitude: params.latitude,
      longitude: params.longitude,
      radius: params.radius,
      connectorTypes: params.connectorTypes,
      amenityIds: params.amenityIds,
      minPrice: params.minPrice,
      maxPrice: params.maxPrice,
      powerOutput: params.powerOutput,
    );
  }
}

class NearestStationsParams extends Equatable {
  const NearestStationsParams({
    required this.latitude,
    required this.longitude,
    this.radius,
    this.connectorTypes,
    this.amenityIds,
    this.minPrice,
    this.maxPrice,
    this.powerOutput,
  });

  final double latitude;
  final double longitude;
  final double? radius;
  final List<String>? connectorTypes;
  final List<int>? amenityIds;
  final double? minPrice;
  final double? maxPrice;
  final double? powerOutput;

  @override
  List<Object?> get props => [
        latitude,
        longitude,
        radius,
        connectorTypes,
        amenityIds,
        minPrice,
        maxPrice,
        powerOutput,
      ];
}

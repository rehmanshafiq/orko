import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

class GetChargingStationDetailUseCase
    implements UseCase<ChargingStationDetailEntity, ChargingStationDetailParams> {
  final ChargingRepository repository;

  const GetChargingStationDetailUseCase(this.repository);

  @override
  Future<Either<Failure, ChargingStationDetailEntity>> call(
    ChargingStationDetailParams params,
  ) {
    return repository.getStationDetail(
      stationId: params.stationId,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class ChargingStationDetailParams extends Equatable {
  const ChargingStationDetailParams({
    required this.stationId,
    required this.latitude,
    required this.longitude,
  });

  final String stationId;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [stationId, latitude, longitude];
}

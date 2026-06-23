import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_stop_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';

/// A persisted trip from `GET /trip-planning/trips/` and `/trips/<id>/`.
class SavedTripEntity extends Equatable {
  const SavedTripEntity({
    required this.id,
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    required this.startSoc,
    required this.totalDistanceKm,
    required this.totalDriveMinutes,
    required this.totalChargingMinutes,
    required this.totalCost,
    required this.currency,
    required this.status,
    required this.createdAt,
    required this.stops,
    this.vehicle,
    this.originAddress,
    this.destinationAddress,
  });

  final int id;
  final UserVehicleEntity? vehicle;
  final double originLatitude;
  final double originLongitude;
  final String? originAddress;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? destinationAddress;
  final double startSoc;
  final double totalDistanceKm;
  final double totalDriveMinutes;
  final double totalChargingMinutes;
  final double totalCost;
  final String currency;

  /// `"planned"` or `"infeasible"`.
  final String status;

  /// Epoch seconds.
  final int createdAt;
  final List<TripStopEntity> stops;

  bool get isFeasible => status != 'infeasible';

  @override
  List<Object?> get props => [
        id,
        vehicle,
        originLatitude,
        originLongitude,
        originAddress,
        destinationLatitude,
        destinationLongitude,
        destinationAddress,
        startSoc,
        totalDistanceKm,
        totalDriveMinutes,
        totalChargingMinutes,
        totalCost,
        currency,
        status,
        createdAt,
        stops,
      ];
}

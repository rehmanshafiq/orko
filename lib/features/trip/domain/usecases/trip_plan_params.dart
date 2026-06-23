import 'package:equatable/equatable.dart';

/// Request parameters shared by `plan-trip` and `save-trip`.
///
/// Defaults mirror the API contract: [startSoc] 100, [targetSoc] 80,
/// [reserveSoc] 10, [corridorKm] 5. Validation: [reserveSoc] must be
/// `< targetSoc` (the server returns 422 otherwise).
class TripPlanParams extends Equatable {
  const TripPlanParams({
    required this.originLatitude,
    required this.originLongitude,
    required this.destinationLatitude,
    required this.destinationLongitude,
    this.originAddress,
    this.destinationAddress,
    this.customerVehicleId,
    this.startSoc = 100,
    this.targetSoc = 80,
    this.reserveSoc = 10,
    this.corridorKm = 5,
  });

  final double originLatitude;
  final double originLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? originAddress;
  final String? destinationAddress;
  final int? customerVehicleId;
  final double startSoc;
  final double targetSoc;
  final double reserveSoc;
  final double corridorKm;

  /// Builds the JSON request body, omitting nulls.
  Map<String, dynamic> toJson() {
    return {
      'origin_latitude': originLatitude,
      'origin_longitude': originLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      if (originAddress != null && originAddress!.isNotEmpty)
        'origin_address': originAddress,
      if (destinationAddress != null && destinationAddress!.isNotEmpty)
        'destination_address': destinationAddress,
      if (customerVehicleId != null) 'customer_vehicle_id': customerVehicleId,
      'start_soc': startSoc,
      'target_soc': targetSoc,
      'reserve_soc': reserveSoc,
      'corridor_km': corridorKm,
    };
  }

  @override
  List<Object?> get props => [
        originLatitude,
        originLongitude,
        destinationLatitude,
        destinationLongitude,
        originAddress,
        destinationAddress,
        customerVehicleId,
        startSoc,
        targetSoc,
        reserveSoc,
        corridorKm,
      ];
}

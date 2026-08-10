import 'package:equatable/equatable.dart';

/// Planning mode requested from `plan-trip` (and, only ever as [optimized],
/// from `save-trip` / `edit-trip`).
///
/// * [optimized] — the default: simulates charging and returns a feasible,
///   costed plan (today's behaviour).
/// * [allStations] — a browse mode that lists every charger along the route
///   without simulating charging. `save-trip` / `edit-trip` reject it with 422,
///   so it must never be sent to those endpoints.
enum TripPlanType { optimized, allStations }

extension TripPlanTypeX on TripPlanType {
  /// The exact value the API expects in the `plan_type` field.
  String get wireValue {
    switch (this) {
      case TripPlanType.optimized:
        return 'optimized';
      case TripPlanType.allStations:
        return 'all_stations';
    }
  }
}

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
    this.planType = TripPlanType.optimized,
  });

  final double originLatitude;
  final double originLongitude;
  final double destinationLatitude;
  final double destinationLongitude;
  final String? originAddress;
  final String? destinationAddress;
  final int? customerVehicleId;
  final int startSoc;
  final int targetSoc;
  final int reserveSoc;
  final int corridorKm;

  /// The planning mode. Serialized only for [TripPlanType.allStations]; the
  /// optimized default is left out so the request body stays exactly as it was
  /// before this field existed (omitting `plan_type` == optimized server-side).
  final TripPlanType planType;

  /// Builds the JSON request body, omitting nulls.
  Map<String, dynamic> toJson() {
    return {
      'origin_latitude': originLatitude,
      'origin_longitude': originLongitude,
      'destination_latitude': destinationLatitude,
      'destination_longitude': destinationLongitude,
      if (originAddress != null && originAddress!.isNotEmpty) 'origin_address': originAddress,
      if (destinationAddress != null && destinationAddress!.isNotEmpty)
        'destination_address': destinationAddress,
      if (customerVehicleId != null) 'customer_vehicle_id': customerVehicleId,
      'start_soc': startSoc,
      'target_soc': targetSoc,
      'reserve_soc': reserveSoc,
      'corridor_km': corridorKm,
      if (planType != TripPlanType.optimized) 'plan_type': planType.wireValue,
    };
  }

  TripPlanParams copyWith({
    double? originLatitude,
    double? originLongitude,
    double? destinationLatitude,
    double? destinationLongitude,
    String? originAddress,
    String? destinationAddress,
    int? customerVehicleId,
    int? startSoc,
    int? targetSoc,
    int? reserveSoc,
    int? corridorKm,
    TripPlanType? planType,
  }) {
    return TripPlanParams(
      originLatitude: originLatitude ?? this.originLatitude,
      originLongitude: originLongitude ?? this.originLongitude,
      destinationLatitude: destinationLatitude ?? this.destinationLatitude,
      destinationLongitude: destinationLongitude ?? this.destinationLongitude,
      originAddress: originAddress ?? this.originAddress,
      destinationAddress: destinationAddress ?? this.destinationAddress,
      customerVehicleId: customerVehicleId ?? this.customerVehicleId,
      startSoc: startSoc ?? this.startSoc,
      targetSoc: targetSoc ?? this.targetSoc,
      reserveSoc: reserveSoc ?? this.reserveSoc,
      corridorKm: corridorKm ?? this.corridorKm,
      planType: planType ?? this.planType,
    );
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
        planType,
      ];
}

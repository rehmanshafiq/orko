class StopChargeInfoModel {
  const StopChargeInfoModel({
    required this.arrivePct,
    required this.departPct,
    required this.minutes,
    required this.costPkr,
    this.distanceFromPreviousStopKm,
    this.amenities = const [],
    this.isThirdParty = false,
  });

  final int arrivePct;
  final int departPct;
  final int minutes;
  final int costPkr;

  /// Distance (km) from the previous stop on the route; null when unknown.
  final double? distanceFromPreviousStopKm;

  /// Amenities available at the stop, e.g. `['Wifi', 'Air Conditioner']`.
  final List<String> amenities;

  /// True when the station is operated by a third party (`is_third_party` key) —
  /// the View Details and Pre-book actions are hidden for these stops.
  final bool isThirdParty;
}


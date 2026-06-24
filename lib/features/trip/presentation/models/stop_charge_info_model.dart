class StopChargeInfoModel {
  const StopChargeInfoModel({
    required this.arrivePct,
    required this.departPct,
    required this.minutes,
    required this.costPkr,
    this.amenities = const [],
  });

  final int arrivePct;
  final int departPct;
  final int minutes;
  final int costPkr;

  /// Amenities available at the stop, e.g. `['Wifi', 'Air Conditioner']`.
  final List<String> amenities;
}


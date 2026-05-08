class RouteStrategyModel {
  const RouteStrategyModel({
    required this.label,
    required this.maxStops,
    required this.avgSpeedKmh,
    required this.departBatteryPct,
    required this.ratePerKwh,
    required this.kwhPerPct,
    required this.stopChargeMinPerPct,
  });

  final String label;
  final int maxStops;
  final double avgSpeedKmh;
  final int departBatteryPct;
  final double ratePerKwh;
  final double kwhPerPct;
  final double stopChargeMinPerPct;
}


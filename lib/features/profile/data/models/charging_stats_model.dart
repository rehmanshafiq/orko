import 'package:orko_hubco/features/profile/domain/entities/charging_stats_entity.dart';

/// Maps the `body` object from `GET api/v1/bookings/charging-stats/`.
/// Parsed defensively so a null/missing/string field can never throw.
class ChargingStatsModel extends ChargingStatsEntity {
  const ChargingStatsModel({
    super.totalCharges,
    super.totalKwh,
    super.totalKm,
    super.co2ReducedKg,
    super.moneySavedPkr,
  });

  factory ChargingStatsModel.fromJson(Map<String, dynamic> json) {
    return ChargingStatsModel(
      totalCharges: _asInt(json['total_charges']),
      totalKwh: _asDouble(json['total_kwh']),
      totalKm: _asDouble(json['total_km']),
      co2ReducedKg: _asDouble(json['co2_reduced_kg']),
      moneySavedPkr: _asDouble(json['money_saved_pkr']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

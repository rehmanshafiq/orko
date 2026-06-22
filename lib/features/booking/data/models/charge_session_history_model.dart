import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';

/// Maps an item of the `body` array from
/// `GET api/v1/bookings/charge-session-history/` into a
/// [ChargeSessionHistoryEntity]. Parsed defensively so a missing, null, or
/// malformed key can never throw.
class ChargeSessionHistoryModel extends ChargeSessionHistoryEntity {
  const ChargeSessionHistoryModel({
    required super.id,
    required super.locationName,
    required super.status,
    super.startedAt,
    super.completedAt,
    super.duration,
    super.energyConsumed,
    super.energyCost,
    super.taxCost,
    super.totalCost,
  });

  factory ChargeSessionHistoryModel.fromJson(Map<String, dynamic> json) {
    return ChargeSessionHistoryModel(
      id: _asInt(json['id']),
      locationName: (json['location_name'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startedAt: _asStringOrNull(json['started_at']),
      completedAt: _asStringOrNull(json['completed_at']),
      duration: _asStringOrNull(json['duration']),
      energyConsumed: _asDoubleOrNull(json['energy_consumed']),
      energyCost: _asDoubleOrNull(json['energy_cost']),
      taxCost: _asDoubleOrNull(json['tax_cost']),
      totalCost: _asDoubleOrNull(json['total_cost']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static String? _asStringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    return str.isEmpty ? null : str;
  }

  static double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

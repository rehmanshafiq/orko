import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';

/// Maps the `body` object from `GET api/v1/bookings/live-session/` into a
/// [LiveSessionEntity]. Parsed defensively so a missing, null, or malformed
/// key can never throw.
class LiveSessionModel extends LiveSessionEntity {
  const LiveSessionModel({
    required super.active,
    super.sessionId,
    super.locationName,
    super.startedAt,
    super.elapsed,
    super.startSoc,
    super.endSoc,
    super.kwhDelivered,
    super.energyCost,
    super.totalCost,
  });

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    return LiveSessionModel(
      active: json['active'] == true,
      sessionId: _asIntOrNull(json['session_id']),
      locationName: _asStringOrNull(json['location_name']),
      startedAt: _asStringOrNull(json['started_at']),
      elapsed: _asStringOrNull(json['elapsed']),
      startSoc: _asDoubleOrNull(json['start_soc']),
      endSoc: _asDoubleOrNull(json['end_soc']),
      kwhDelivered: _asDoubleOrNull(json['kwh_delivered']),
      energyCost: _asDoubleOrNull(json['energy_cost']),
      totalCost: _asDoubleOrNull(json['total_cost']),
    );
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
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

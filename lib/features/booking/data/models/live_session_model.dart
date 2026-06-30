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
    super.sessionTime,
    super.energyDeliveredKwh,
    super.chargingSpeedKw,
    super.currentChargePercentage,
    super.currentCost,
    super.timeLeft,
    super.openingTime,
    super.closingTime,
    super.contactNumber,
    super.countryCode,
    super.pricingMode,
    super.currency,
    super.price,
  });

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    // Both `operating_hours` and `pricing` are nested objects that may be
    // absent or null in leaner payloads — read them defensively.
    final operatingHours = _asMapOrNull(json['operating_hours']);
    final pricing = _asMapOrNull(json['pricing']);

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
      sessionTime: _asStringOrNull(json['session_time']),
      energyDeliveredKwh: _asDoubleOrNull(json['energy_delivered_kwh']),
      chargingSpeedKw: _asDoubleOrNull(json['charging_speed_kw']),
      currentChargePercentage:
          _asDoubleOrNull(json['current_charge_percentage']),
      currentCost: _asDoubleOrNull(json['current_cost']),
      timeLeft: _asStringOrNull(json['time_left']),
      openingTime: _asStringOrNull(operatingHours?['opening_time']),
      closingTime: _asStringOrNull(operatingHours?['closing_time']),
      contactNumber: _asStringOrNull(json['contact_number']),
      countryCode: _asStringOrNull(json['country_code']),
      pricingMode: _asStringOrNull(pricing?['pricing_mode']),
      currency: _asStringOrNull(pricing?['currency']),
      price: _asDoubleOrNull(pricing?['price']),
    );
  }

  static Map<String, dynamic>? _asMapOrNull(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
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

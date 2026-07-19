import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';

/// Maps the `body` object from `GET api/v1/bookings/live-session/` into a
/// [LiveSessionEntity]. Parsed defensively so a missing, null, or malformed
/// key can never throw.
class LiveSessionModel extends LiveSessionEntity {
  const LiveSessionModel({
    required super.active,
    super.isWalkinSession,
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
    super.bookingDate,
    super.bookingStartTime,
    super.bookingEndTime,
  });

  factory LiveSessionModel.fromJson(Map<String, dynamic> json) {
    // `operating_hours`, `pricing`, and `booking` are nested objects that may
    // be absent or null in leaner payloads — read them defensively.
    final operatingHours = _asMapOrNull(json['operating_hours']);
    final pricing = _asMapOrNull(json['pricing']);
    final booking = _asMapOrNull(json['booking']);

    return LiveSessionModel(
      active: json['active'] == true,
      isWalkinSession: _asBool(json['is_walkin_session']),
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
      bookingDate: _asStringOrNull(booking?['booking_date']),
      bookingStartTime: _asStringOrNull(booking?['start_time']),
      bookingEndTime: _asStringOrNull(booking?['end_time']),
    );
  }

  static Map<String, dynamic>? _asMapOrNull(dynamic value) {
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  /// Coerces the backend's `is_walkin_session` flag to a bool, tolerating a
  /// real bool, `1`/`0`, or `"true"`/`"false"` strings. Anything else (or a
  /// missing key) is treated as false.
  static bool _asBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) {
      final str = value.trim().toLowerCase();
      return str == 'true' || str == '1';
    }
    return false;
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

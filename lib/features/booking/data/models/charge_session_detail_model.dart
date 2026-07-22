import 'package:orko_hubco/features/booking/domain/entities/charge_session_detail_entity.dart';

/// Maps the `body` object from
/// `GET api/v1/bookings/charge-session-details/?id=<session_id>` into a
/// [ChargeSessionDetailEntity]. Parsed defensively — the backend mixes types
/// freely (numbers, `"12.50"` decimal strings, and the literal `"N/A"`), so a
/// missing, null, or malformed key can never throw.
class ChargeSessionDetailModel extends ChargeSessionDetailEntity {
  const ChargeSessionDetailModel({
    required super.id,
    required super.status,
    super.startedAt,
    super.completedAt,
    super.duration,
    super.energyConsumed,
    super.energyCost,
    super.taxCost,
    super.totalCost,
    super.rate,
    super.avgPower,
    super.startSoc,
    super.endSoc,
    super.co2ReducedKg,
    super.energyConsumptionValues,
    super.locationName,
    super.cityName,
    super.chargePointId,
    super.connectorId,
    super.make,
    super.model,
    super.vehicleRegNo,
    super.bookingDate,
    super.bookingStartTime,
    super.bookingEndTime,
    super.paymentMethod,
  });

  factory ChargeSessionDetailModel.fromJson(Map<String, dynamic> json) {
    // The booking slot arrives nested under `booking`; absent for ad-hoc
    // sessions that weren't pre-booked.
    final booking = json['booking'];
    final bookingMap = booking is Map ? booking : const {};
    return ChargeSessionDetailModel(
      id: _asInt(json['id']),
      status: (json['status'] ?? '').toString(),
      startedAt: _asStringOrNull(json['started_at']),
      completedAt: _asStringOrNull(json['completed_at']),
      duration: _asStringOrNull(json['duration']),
      energyConsumed: _asDoubleOrNull(
        json['energy_consumed'] ?? json['total_energy_consumed'],
      ),
      energyCost: _asDoubleOrNull(json['energy_cost']),
      taxCost: _asDoubleOrNull(json['tax_cost']),
      totalCost: _asDoubleOrNull(json['total_cost']),
      rate: _asDoubleOrNull(json['rate']),
      avgPower: _asDoubleOrNull(json['avg_power']),
      startSoc: _asDoubleOrNull(json['start_soc']),
      endSoc: _asDoubleOrNull(json['end_soc']),
      co2ReducedKg: _asDoubleOrNull(json['co2_reduced_kg']),
      energyConsumptionValues: _asPoints(json['energy_consumption_values']),
      locationName: _asStringOrNull(json['location_name']),
      cityName: _asStringOrNull(json['city_name']),
      chargePointId: _asStringOrNull(json['charge_point_id']),
      connectorId: _asIntOrNull(json['connector_id']),
      make: _asStringOrNull(json['make']),
      model: _asStringOrNull(json['model']),
      vehicleRegNo: _asStringOrNull(json['vehicle_reg_no']),
      bookingDate: _asStringOrNull(bookingMap['booking_date']),
      bookingStartTime: _asStringOrNull(bookingMap['start_time']),
      bookingEndTime: _asStringOrNull(bookingMap['end_time']),
      paymentMethod: _asStringOrNull(json['payment_method']),
    );
  }

  /// Graph points arrive as `[{timestamp, value}, …]`; anything else (missing,
  /// null, malformed entries) collapses to an empty list.
  static List<EnergyConsumptionPoint> _asPoints(dynamic value) {
    if (value is! List) return const [];
    final points = <EnergyConsumptionPoint>[];
    for (final item in value) {
      if (item is! Map) continue;
      final timestamp = _asStringOrNull(item['timestamp']);
      final kwh = _asDoubleOrNull(item['value']);
      if (timestamp == null || kwh == null) continue;
      points.add(EnergyConsumptionPoint(timestamp: timestamp, value: kwh));
    }
    return List.unmodifiable(points);
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim()) ?? 0;
    return 0;
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }

  /// Null for absent/empty values AND for the backend's `"N/A"` placeholder,
  /// so the UI's fallback rendering kicks in uniformly.
  static String? _asStringOrNull(dynamic value) {
    if (value == null) return null;
    final str = value.toString().trim();
    if (str.isEmpty || str.toLowerCase() == 'n/a') return null;
    return str;
  }

  static double? _asDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.trim());
    return null;
  }
}

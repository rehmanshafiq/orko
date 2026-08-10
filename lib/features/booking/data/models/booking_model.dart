import 'package:orko_hubco/features/booking/domain/entities/booking_entity.dart';

class BookingModel extends BookingEntity {
  const BookingModel({
    required super.id,
    required super.bookingDate,
    required super.startTime,
    required super.endTime,
    required super.bookingStatus,
    required super.location,
    super.chargeStation,
    super.chargerConnector,
    super.minutesMobile,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: _asInt(json['id']),
      bookingDate: (json['booking_date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      bookingStatus: (json['booking_status'] ?? '').toString(),
      location: _asInt(json['location']),
      chargeStation: _asIntOrNull(json['charge_station']),
      chargerConnector: _asIntOrNull(json['charger_connector']),
      minutesMobile: _asIntOrNull(json['minutes_mobile']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static int? _asIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }
}

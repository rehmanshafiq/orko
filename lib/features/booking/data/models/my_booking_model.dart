import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';

class BookingChargerInfoModel extends BookingChargerInfoEntity {
  const BookingChargerInfoModel({
    required super.connectorType,
    required super.powerType,
    required super.power,
  });

  factory BookingChargerInfoModel.fromJson(Map<String, dynamic> json) {
    return BookingChargerInfoModel(
      connectorType: (json['connector_type'] ?? '').toString(),
      powerType: (json['power_type'] ?? '').toString(),
      power: (json['power'] ?? '').toString(),
    );
  }
}

class BookingCostModel extends BookingCostEntity {
  const BookingCostModel({
    required super.amount,
    required super.currency,
    required super.pricingMode,
  });

  factory BookingCostModel.fromJson(Map<String, dynamic> json) {
    return BookingCostModel(
      amount: _asDouble(json['amount']),
      currency: (json['currency'] ?? '').toString(),
      pricingMode: (json['pricing_mode'] ?? '').toString(),
    );
  }

  static double _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}

class MyBookingModel extends MyBookingEntity {
  const MyBookingModel({
    required super.id,
    required super.stationName,
    required super.locationName,
    required super.date,
    required super.startTime,
    required super.endTime,
    required super.bookingStatus,
    required super.bookingCode,
    required super.locationId,
    required super.locationLat,
    required super.locationLong,
    required super.currentChargeState,
    required super.desireChargeState,
    required super.reschedule,
    required super.canReschedule,
    required super.canCancel,
    super.chargerInfo,
    super.estimatedCost,
  });

  factory MyBookingModel.fromJson(Map<String, dynamic> json) {
    final rawCharger = json['charger_info'];
    final rawCost = json['estimated_cost'];
    return MyBookingModel(
      id: _asInt(json['id']),
      stationName: (json['station_name'] ?? '').toString(),
      locationName: (json['location_name'] ?? '').toString(),
      date: (json['date'] ?? '').toString(),
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      bookingStatus: (json['booking_status'] ?? '').toString(),
      bookingCode: (json['booking_code'] ?? '').toString(),
      locationId: _asInt(json['location_id']),
      locationLat: _asDouble(json['location_lat']),
      locationLong: _asDouble(json['location_long']),
      currentChargeState: json['current_charge_state'] as num?,
      desireChargeState: json['desire_charge_state'] as num?,
      reschedule: _asInt(json['reschedule']),
      canReschedule: json['can_reschedule'] == true,
      canCancel: json['can_cancel'] == true,
      chargerInfo: rawCharger is Map
          ? BookingChargerInfoModel.fromJson(
              Map<String, dynamic>.from(rawCharger))
          : null,
      estimatedCost: rawCost is Map
          ? BookingCostModel.fromJson(Map<String, dynamic>.from(rawCost))
          : null,
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

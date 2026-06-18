import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';

class BookingSlotModel extends BookingSlotEntity {
  const BookingSlotModel({
    required super.startTime,
    required super.endTime,
    required super.isAvailable,
  });

  factory BookingSlotModel.fromJson(Map<String, dynamic> json) {
    return BookingSlotModel(
      startTime: (json['start_time'] ?? '').toString(),
      endTime: (json['end_time'] ?? '').toString(),
      isAvailable: json['is_available'] == true,
    );
  }
}

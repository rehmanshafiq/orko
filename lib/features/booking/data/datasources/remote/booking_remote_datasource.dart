import 'package:orko_hubco/features/booking/data/models/booking_model.dart';
import 'package:orko_hubco/features/booking/data/models/booking_slot_model.dart';
import 'package:orko_hubco/features/booking/data/models/charge_session_history_model.dart';
import 'package:orko_hubco/features/booking/data/models/charger_details_model.dart';
import 'package:orko_hubco/features/booking/data/models/my_booking_model.dart';

abstract class BookingRemoteDataSource {
  Future<ChargerDetailsModel> getChargerDetails({required int locationId});

  Future<List<BookingSlotModel>> getSlots({
    required String date,
    required int locationId,
  });

  Future<BookingModel> createBooking({
    required String bookingDate,
    required String startTime,
    required String endTime,
    required int location,
  });

  Future<BookingModel> createBookingHgl({
    required String bookingDate,
    required String startTime,
    required int location,
  });

  Future<List<MyBookingModel>> getMyBookings();

  Future<List<ChargeSessionHistoryModel>> getChargeSessionHistory();

  Future<String> cancelBooking({required int bookingId});

  Future<BookingModel> rescheduleBooking({
    required int bookingId,
    required String bookingDate,
    required String startTime,
    required int location,
  });
}

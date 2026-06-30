import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/charger_details_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/verify_qr_result_entity.dart';

abstract class BookingRepository {
  /// `GET /bookings/charger-details/` — station info + connectors for a location.
  Future<Either<Failure, ChargerDetailsEntity>> getChargerDetails({
    required int locationId,
  });

  /// `GET /bookings/slots/` — slots for [date] (`YYYY-MM-DD`) at [locationId].
  Future<Either<Failure, List<BookingSlotEntity>>> getSlots({
    required String date,
    required int locationId,
  });

  /// `POST /bookings/book-charging-session/` — primary booking endpoint.
  /// Booking starts in `pending_approval`.
  Future<Either<Failure, BookingEntity>> createBooking({
    required String bookingDate,
    required String startTime,
    required String endTime,
    required int location,
  });

  /// `POST /bookings/book-charge-session/` — HGL simplified endpoint.
  /// `end_time` is auto-calculated (start + 30 min); status is `approved`.
  Future<Either<Failure, BookingEntity>> createBookingHgl({
    required String bookingDate,
    required String startTime,
    required int location,
    int? vehicleId,
  });

  /// `GET /bookings/my-charging-sessions/` — approved + cancelled bookings.
  Future<Either<Failure, List<MyBookingEntity>>> getMyBookings();

  /// `GET /bookings/charge-session-history/` — completed & in-progress sessions.
  Future<Either<Failure, List<ChargeSessionHistoryEntity>>>
      getChargeSessionHistory();

  /// `GET /bookings/live-session/` — the user's currently-running session, if any.
  Future<Either<Failure, LiveSessionEntity>> getLiveSession();

  /// `POST /bookings/cancel-booking/` — returns the success message.
  Future<Either<Failure, String>> cancelBooking({required int bookingId});

  /// `POST /bookings/reschedule-booking/` — creates a new linked booking.
  /// `end_time` is auto-derived by the backend and must NOT be sent.
  Future<Either<Failure, BookingEntity>> rescheduleBooking({
    required int bookingId,
    required String bookingDate,
    required String startTime,
    required int location,
  });

  /// `POST /bookings/verify-qr/` — verifies a scanned charger QR (charge point
  /// + connector) against the user's approved booking.
  ///
  /// Returns a [VerifyQrResultEntity] for both a match (`200`) and a wrong
  /// connector (`422`); only transport/auth/server errors surface as a
  /// [Failure].
  Future<Either<Failure, VerifyQrResultEntity>> verifyQr({
    required String bookingCode,
    required String chargePointId,
    required int connectorId,
  });
}

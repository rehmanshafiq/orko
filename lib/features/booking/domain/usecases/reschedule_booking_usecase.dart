import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class RescheduleBookingUseCase
    implements UseCase<BookingEntity, RescheduleBookingParams> {
  final BookingRepository repository;

  const RescheduleBookingUseCase(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(RescheduleBookingParams params) {
    return repository.rescheduleBooking(
      bookingId: params.bookingId,
      bookingDate: params.bookingDate,
      startTime: params.startTime,
      location: params.location,
      noOfSlots: params.noOfSlots,
    );
  }
}

class RescheduleBookingParams {
  const RescheduleBookingParams({
    required this.bookingId,
    required this.bookingDate,
    required this.startTime,
    required this.location,
    this.noOfSlots = 1,
  });

  final int bookingId;
  final String bookingDate;
  final String startTime;
  final int location;

  /// Number of consecutive 30-min slots (1 or 2). [startTime] is the start of
  /// the first slot; the backend reserves the following slot too when 2.
  final int noOfSlots;
}

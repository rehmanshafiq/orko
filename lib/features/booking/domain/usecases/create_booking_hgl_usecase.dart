import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

/// HGL simplified booking: `end_time` is auto-calculated, status is `approved`.
class CreateBookingHglUseCase
    implements UseCase<BookingEntity, CreateBookingHglParams> {
  final BookingRepository repository;

  const CreateBookingHglUseCase(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(CreateBookingHglParams params) {
    return repository.createBookingHgl(
      bookingDate: params.bookingDate,
      startTime: params.startTime,
      location: params.location,
      vehicleId: params.vehicleId,
      noOfSlots: params.noOfSlots,
    );
  }
}

class CreateBookingHglParams {
  const CreateBookingHglParams({
    required this.bookingDate,
    required this.startTime,
    required this.location,
    this.vehicleId,
    this.noOfSlots = 1,
  });

  final String bookingDate;
  final String startTime;
  final int location;

  /// User vehicle resolved by the compatibility gate; sent as `vehicle_id`.
  final int? vehicleId;

  /// Number of consecutive 30-min slots (1 or 2). [startTime] is the start of
  /// the first slot; the backend reserves the following slot too when 2.
  final int noOfSlots;
}

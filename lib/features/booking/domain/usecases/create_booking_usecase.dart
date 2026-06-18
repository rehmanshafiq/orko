import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class CreateBookingUseCase
    implements UseCase<BookingEntity, CreateBookingParams> {
  final BookingRepository repository;

  const CreateBookingUseCase(this.repository);

  @override
  Future<Either<Failure, BookingEntity>> call(CreateBookingParams params) {
    return repository.createBooking(
      bookingDate: params.bookingDate,
      startTime: params.startTime,
      endTime: params.endTime,
      location: params.location,
    );
  }
}

class CreateBookingParams {
  const CreateBookingParams({
    required this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.location,
  });

  final String bookingDate;
  final String startTime;
  final String endTime;
  final int location;
}

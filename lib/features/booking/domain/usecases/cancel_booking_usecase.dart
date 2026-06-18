import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class CancelBookingUseCase implements UseCase<String, CancelBookingParams> {
  final BookingRepository repository;

  const CancelBookingUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(CancelBookingParams params) {
    return repository.cancelBooking(bookingId: params.bookingId);
  }
}

class CancelBookingParams {
  const CancelBookingParams({required this.bookingId});

  final int bookingId;
}

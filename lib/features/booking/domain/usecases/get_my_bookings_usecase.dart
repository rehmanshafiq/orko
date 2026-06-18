import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class GetMyBookingsUseCase
    implements UseCase<List<MyBookingEntity>, NoParams> {
  final BookingRepository repository;

  const GetMyBookingsUseCase(this.repository);

  @override
  Future<Either<Failure, List<MyBookingEntity>>> call(NoParams params) {
    return repository.getMyBookings();
  }
}

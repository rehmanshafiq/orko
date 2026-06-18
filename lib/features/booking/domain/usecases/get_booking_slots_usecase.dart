import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class GetBookingSlotsUseCase
    implements UseCase<List<BookingSlotEntity>, GetBookingSlotsParams> {
  final BookingRepository repository;

  const GetBookingSlotsUseCase(this.repository);

  @override
  Future<Either<Failure, List<BookingSlotEntity>>> call(
    GetBookingSlotsParams params,
  ) {
    return repository.getSlots(date: params.date, locationId: params.locationId);
  }
}

class GetBookingSlotsParams {
  const GetBookingSlotsParams({required this.date, required this.locationId});

  /// `YYYY-MM-DD`.
  final String date;
  final int locationId;
}

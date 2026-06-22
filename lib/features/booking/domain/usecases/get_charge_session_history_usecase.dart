import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class GetChargeSessionHistoryUseCase
    implements UseCase<List<ChargeSessionHistoryEntity>, NoParams> {
  final BookingRepository repository;

  const GetChargeSessionHistoryUseCase(this.repository);

  @override
  Future<Either<Failure, List<ChargeSessionHistoryEntity>>> call(
    NoParams params,
  ) {
    return repository.getChargeSessionHistory();
  }
}

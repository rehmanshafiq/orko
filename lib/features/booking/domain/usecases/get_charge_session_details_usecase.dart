import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_detail_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

/// Fetches full details of one of the user's charging sessions
/// (`charge-session-details`), used by the post-session summary screen.
class GetChargeSessionDetailsUseCase
    implements UseCase<ChargeSessionDetailEntity, GetChargeSessionDetailsParams> {
  final BookingRepository repository;

  const GetChargeSessionDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, ChargeSessionDetailEntity>> call(
    GetChargeSessionDetailsParams params,
  ) {
    return repository.getChargeSessionDetails(sessionId: params.sessionId);
  }
}

class GetChargeSessionDetailsParams {
  const GetChargeSessionDetailsParams({required this.sessionId});

  final int sessionId;
}

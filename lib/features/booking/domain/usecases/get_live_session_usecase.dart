import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class GetLiveSessionUseCase implements UseCase<LiveSessionEntity, NoParams> {
  final BookingRepository repository;

  const GetLiveSessionUseCase(this.repository);

  @override
  Future<Either<Failure, LiveSessionEntity>> call(NoParams params) {
    return repository.getLiveSession();
  }
}

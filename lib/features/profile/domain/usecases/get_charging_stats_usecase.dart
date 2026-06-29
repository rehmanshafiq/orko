import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/profile/domain/entities/charging_stats_entity.dart';
import 'package:orko_hubco/features/profile/domain/repositories/profile_repository.dart';

/// Fetches the user's aggregated charging stats (`charging_stats`).
class GetChargingStatsUseCase
    implements UseCase<ChargingStatsEntity, NoParams> {
  final ProfileRepository repository;

  const GetChargingStatsUseCase(this.repository);

  @override
  Future<Either<Failure, ChargingStatsEntity>> call(NoParams params) {
    return repository.getChargingStats();
  }
}

import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/profile/domain/entities/charging_stats_entity.dart';

/// Abstract profile repository contract.
abstract class ProfileRepository {
  /// Fetches the user's aggregated charging stats.
  Future<Either<Failure, ChargingStatsEntity>> getChargingStats();
}

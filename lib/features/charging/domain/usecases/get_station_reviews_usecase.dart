import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/entities/station_reviews_entity.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

/// Fetches the reviews list + rating summary for a location.
class GetStationReviewsUseCase implements UseCase<StationReviewsEntity, int> {
  final ChargingRepository repository;

  const GetStationReviewsUseCase(this.repository);

  @override
  Future<Either<Failure, StationReviewsEntity>> call(int locationId) {
    return repository.getReviews(locationId);
  }
}

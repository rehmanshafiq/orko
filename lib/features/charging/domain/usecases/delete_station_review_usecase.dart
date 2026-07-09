import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

/// Deletes the current user's review by id.
class DeleteStationReviewUseCase implements UseCase<void, int> {
  final ChargingRepository repository;

  const DeleteStationReviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(int reviewId) {
    return repository.deleteReview(reviewId);
  }
}

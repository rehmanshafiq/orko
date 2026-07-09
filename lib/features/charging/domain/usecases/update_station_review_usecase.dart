import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

class UpdateStationReviewParams extends Equatable {
  const UpdateStationReviewParams({
    required this.reviewId,
    required this.rating,
    required this.description,
  });

  final int reviewId;
  final int rating;
  final String description;

  @override
  List<Object?> get props => [reviewId, rating, description];
}

/// Updates the current user's existing review.
class UpdateStationReviewUseCase
    implements UseCase<void, UpdateStationReviewParams> {
  final ChargingRepository repository;

  const UpdateStationReviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(UpdateStationReviewParams params) {
    return repository.updateReview(
      reviewId: params.reviewId,
      rating: params.rating,
      description: params.description,
    );
  }
}

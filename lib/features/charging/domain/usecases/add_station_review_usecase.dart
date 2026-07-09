import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

class AddStationReviewParams extends Equatable {
  const AddStationReviewParams({
    required this.locationId,
    required this.rating,
    required this.description,
  });

  final int locationId;
  final int rating;
  final String description;

  @override
  List<Object?> get props => [locationId, rating, description];
}

/// Adds the current user's review for a location.
class AddStationReviewUseCase
    implements UseCase<void, AddStationReviewParams> {
  final ChargingRepository repository;

  const AddStationReviewUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(AddStationReviewParams params) {
    return repository.addReview(
      locationId: params.locationId,
      rating: params.rating,
      description: params.description,
    );
  }
}

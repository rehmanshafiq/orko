import 'package:equatable/equatable.dart';

/// A single review returned by `GET api/v1/charging-station/reviews/`.
class StationReviewItemEntity extends Equatable {
  const StationReviewItemEntity({
    required this.id,
    required this.locationId,
    required this.customerId,
    required this.customerName,
    required this.rating,
    required this.description,
    this.customerProfilePicture,
    this.createdAt = '',
    this.isCurrentUser = false,
  });

  final int id;
  final int locationId;
  final int customerId;
  final String customerName;
  final String? customerProfilePicture;

  /// Integer star rating, 1–5.
  final int rating;
  final String description;

  /// Human-readable relative time, e.g. `2 days ago` (server-formatted).
  final String createdAt;

  /// True for the logged-in user's own review (always sorted first by the API).
  final bool isCurrentUser;

  @override
  List<Object?> get props => [
        id,
        locationId,
        customerId,
        customerName,
        customerProfilePicture,
        rating,
        description,
        createdAt,
        isCurrentUser,
      ];
}

/// Rating distribution as percentages (0–100) across the four buckets:
/// rating 1 → [belowAverage], 2 → [average], 3 & 4 → [good], 5 → [excellent].
class ReviewStatusEntity extends Equatable {
  const ReviewStatusEntity({
    this.belowAverage = 0,
    this.average = 0,
    this.good = 0,
    this.excellent = 0,
  });

  final double belowAverage;
  final double average;
  final double good;
  final double excellent;

  @override
  List<Object?> get props => [belowAverage, average, good, excellent];
}

/// Aggregate payload for a station's reviews (list + summary).
class StationReviewsEntity extends Equatable {
  const StationReviewsEntity({
    this.reviews = const [],
    this.reviewStatus = const ReviewStatusEntity(),
    this.totalCount = 0,
    this.averageRating = 0,
  });

  final List<StationReviewItemEntity> reviews;
  final ReviewStatusEntity reviewStatus;
  final int totalCount;
  final double averageRating;

  /// The logged-in user's own review, or null when they haven't reviewed yet.
  StationReviewItemEntity? get currentUserReview {
    for (final r in reviews) {
      if (r.isCurrentUser) return r;
    }
    return null;
  }

  @override
  List<Object?> get props => [reviews, reviewStatus, totalCount, averageRating];
}

import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/charging/domain/entities/station_reviews_entity.dart';

enum StationReviewsStatus { initial, loading, success, failure }

class StationReviewsState extends Equatable {
  const StationReviewsState({
    this.status = StationReviewsStatus.initial,
    this.errorMessage = '',
    this.reviews = const [],
    this.reviewStatus = const ReviewStatusEntity(),
    this.totalCount = 0,
    this.averageRating = 0,
    this.submitting = false,
    this.actionMessage = '',
    this.actionIsError = false,
    this.actionEventId = 0,
  });

  final StationReviewsStatus status;
  final String errorMessage;

  final List<StationReviewItemEntity> reviews;
  final ReviewStatusEntity reviewStatus;
  final int totalCount;
  final double averageRating;

  /// True while an add/update/delete request is in flight.
  final bool submitting;

  /// Transient message for the last add/update/delete outcome. Paired with
  /// [actionEventId] so a listener fires even on repeated identical text.
  final String actionMessage;
  final bool actionIsError;
  final int actionEventId;

  bool get isLoading => status == StationReviewsStatus.loading;
  bool get isFailure => status == StationReviewsStatus.failure;
  bool get isSuccess => status == StationReviewsStatus.success;

  /// The logged-in user's own review, or null when they haven't reviewed yet.
  StationReviewItemEntity? get currentUserReview {
    for (final r in reviews) {
      if (r.isCurrentUser) return r;
    }
    return null;
  }

  bool get hasCurrentUserReview => currentUserReview != null;

  StationReviewsState copyWith({
    StationReviewsStatus? status,
    String? errorMessage,
    List<StationReviewItemEntity>? reviews,
    ReviewStatusEntity? reviewStatus,
    int? totalCount,
    double? averageRating,
    bool? submitting,
    String? actionMessage,
    bool? actionIsError,
    int? actionEventId,
  }) {
    return StationReviewsState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      reviews: reviews ?? this.reviews,
      reviewStatus: reviewStatus ?? this.reviewStatus,
      totalCount: totalCount ?? this.totalCount,
      averageRating: averageRating ?? this.averageRating,
      submitting: submitting ?? this.submitting,
      actionMessage: actionMessage ?? this.actionMessage,
      actionIsError: actionIsError ?? this.actionIsError,
      actionEventId: actionEventId ?? this.actionEventId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        reviews,
        reviewStatus,
        totalCount,
        averageRating,
        submitting,
        actionMessage,
        actionIsError,
        actionEventId,
      ];
}

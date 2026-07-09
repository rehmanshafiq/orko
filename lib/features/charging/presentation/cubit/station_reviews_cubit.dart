import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/charging/domain/usecases/add_station_review_usecase.dart';
import 'package:orko_hubco/features/charging/domain/usecases/delete_station_review_usecase.dart';
import 'package:orko_hubco/features/charging/domain/usecases/get_station_reviews_usecase.dart';
import 'package:orko_hubco/features/charging/domain/usecases/update_station_review_usecase.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/station_reviews_state.dart';

/// Owns the reviews section for a single station: loads the list + summary and
/// performs add / update / delete, reloading after every mutation so the
/// ordering, counts and rating breakdown stay authoritative (server-computed).
class StationReviewsCubit extends Cubit<StationReviewsState> {
  StationReviewsCubit({
    required int locationId,
    required GetStationReviewsUseCase getReviewsUseCase,
    required AddStationReviewUseCase addReviewUseCase,
    required UpdateStationReviewUseCase updateReviewUseCase,
    required DeleteStationReviewUseCase deleteReviewUseCase,
  })  : _locationId = locationId,
        _getReviewsUseCase = getReviewsUseCase,
        _addReviewUseCase = addReviewUseCase,
        _updateReviewUseCase = updateReviewUseCase,
        _deleteReviewUseCase = deleteReviewUseCase,
        super(const StationReviewsState());

  final int _locationId;
  final GetStationReviewsUseCase _getReviewsUseCase;
  final AddStationReviewUseCase _addReviewUseCase;
  final UpdateStationReviewUseCase _updateReviewUseCase;
  final DeleteStationReviewUseCase _deleteReviewUseCase;

  /// Max review body length enforced by the backend and mirrored in the UI.
  static const int maxDescriptionLength = 200;

  /// Loads (or reloads) the reviews list. Shows the full-section spinner only
  /// on the first load; silent refreshes after mutations keep the list visible.
  Future<void> load({bool silent = false}) async {
    if (!silent) {
      emit(state.copyWith(
        status: StationReviewsStatus.loading,
        errorMessage: '',
      ));
    }

    final result = await _getReviewsUseCase(_locationId);
    if (isClosed) return;

    result.fold(
      (failure) {
        // A silent refresh failure keeps the existing list; only surface a
        // full-screen error on the initial load.
        if (silent) return;
        emit(state.copyWith(
          status: StationReviewsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (data) => emit(state.copyWith(
        status: StationReviewsStatus.success,
        errorMessage: '',
        reviews: data.reviews,
        reviewStatus: data.reviewStatus,
        totalCount: data.totalCount,
        averageRating: data.averageRating,
      )),
    );
  }

  /// Adds a new review or updates the user's existing one. Validates locally
  /// before hitting the network; reloads and emits a success/error signal.
  Future<void> submitReview({
    required int rating,
    required String description,
  }) async {
    if (state.submitting) return;

    final trimmed = description.trim();
    final validationError = _validate(rating: rating, description: trimmed);
    if (validationError != null) {
      _emitAction(validationError, isError: true);
      return;
    }

    emit(state.copyWith(submitting: true));

    final existing = state.currentUserReview;
    final result = existing != null
        ? await _updateReviewUseCase(
            UpdateStationReviewParams(
              reviewId: existing.id,
              rating: rating,
              description: trimmed,
            ),
          )
        : await _addReviewUseCase(
            AddStationReviewParams(
              locationId: _locationId,
              rating: rating,
              description: trimmed,
            ),
          );
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(state.copyWith(submitting: false));
        _emitAction(
          failure.message.isNotEmpty
              ? failure.message
              : 'Could not save your review. Please try again.',
          isError: true,
        );
        // On a duplicate-review conflict the server already has a review we
        // didn't know about — refresh so the UI switches to edit mode.
        if (failure.statusCode == 422) await load(silent: true);
      },
      (_) async {
        await load(silent: true);
        if (isClosed) return;
        emit(state.copyWith(submitting: false));
        _emitAction(
          existing != null ? 'Review updated.' : 'Review added.',
          isError: false,
        );
      },
    );
  }

  /// Deletes the logged-in user's review, if any.
  Future<void> deleteMyReview() async {
    if (state.submitting) return;
    final existing = state.currentUserReview;
    if (existing == null) return;

    emit(state.copyWith(submitting: true));

    final result = await _deleteReviewUseCase(existing.id);
    if (isClosed) return;

    await result.fold(
      (failure) async {
        emit(state.copyWith(submitting: false));
        _emitAction(
          failure.message.isNotEmpty
              ? failure.message
              : 'Could not delete your review. Please try again.',
          isError: true,
        );
      },
      (_) async {
        await load(silent: true);
        if (isClosed) return;
        emit(state.copyWith(submitting: false));
        _emitAction('Review deleted.', isError: false);
      },
    );
  }

  String? _validate({required int rating, required String description}) {
    if (rating < 1 || rating > 5) return 'Please select a rating.';
    if (description.isEmpty) return 'Please write a short review.';
    if (description.length > maxDescriptionLength) {
      return 'Review must be $maxDescriptionLength characters or fewer.';
    }
    return null;
  }

  void _emitAction(String message, {required bool isError}) {
    emit(state.copyWith(
      actionMessage: message,
      actionIsError: isError,
      actionEventId: state.actionEventId + 1,
    ));
  }
}

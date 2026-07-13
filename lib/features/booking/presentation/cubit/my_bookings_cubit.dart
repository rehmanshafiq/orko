import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/booking/domain/usecases/cancel_booking_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_charge_session_history_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_live_session_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_my_bookings_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/reschedule_booking_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/verify_qr_usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/verify_qr_result_entity.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

/// Outcome of a cancel/reschedule action, surfaced to the view for snackbars.
typedef BookingActionResult = ({bool success, String message});

class MyBookingsCubit extends Cubit<MyBookingsState> {
  MyBookingsCubit({
    required GetMyBookingsUseCase getMyBookingsUseCase,
    required GetChargeSessionHistoryUseCase getChargeSessionHistoryUseCase,
    required GetLiveSessionUseCase getLiveSessionUseCase,
    required CancelBookingUseCase cancelBookingUseCase,
    required RescheduleBookingUseCase rescheduleBookingUseCase,
    required VerifyQrUseCase verifyQrUseCase,
  })  : _getMyBookingsUseCase = getMyBookingsUseCase,
        _getChargeSessionHistoryUseCase = getChargeSessionHistoryUseCase,
        _getLiveSessionUseCase = getLiveSessionUseCase,
        _cancelBookingUseCase = cancelBookingUseCase,
        _rescheduleBookingUseCase = rescheduleBookingUseCase,
        _verifyQrUseCase = verifyQrUseCase,
        super(const MyBookingsState());

  final GetMyBookingsUseCase _getMyBookingsUseCase;
  final GetChargeSessionHistoryUseCase _getChargeSessionHistoryUseCase;
  final GetLiveSessionUseCase _getLiveSessionUseCase;
  final CancelBookingUseCase _cancelBookingUseCase;
  final RescheduleBookingUseCase _rescheduleBookingUseCase;
  final VerifyQrUseCase _verifyQrUseCase;

  /// Switches the Approved/Cancelled sub-tab within the Upcoming tab. Both lists
  /// are derived from the already-loaded my-bookings data, so no refetch needed.
  void selectUpcomingFilter(UpcomingFilter filter) {
    if (filter == state.upcomingFilter) return;
    emit(state.copyWith(upcomingFilter: filter));
  }

  void selectTab(BookingTab tab) {
    emit(state.copyWith(selectedTab: tab));
    // Refresh from the my_bookings API every time the Upcoming tab is opened.
    if (tab == BookingTab.upcoming) {
      loadBookings(showSpinner: false);
    }
    // Fetch the live session whenever Active is opened — with a spinner on the
    // first visit, silently on refreshes.
    if (tab == BookingTab.active) {
      loadLiveSession(
        showSpinner: state.liveStatus != MyBookingsStatus.success,
      );
    }
    // Load charging history the first time History is opened, and refresh it
    // silently on subsequent visits.
    if (tab == BookingTab.history) {
      loadHistory(
        showSpinner: state.historyStatus != MyBookingsStatus.success,
      );
    }
  }

  /// Loads (or reloads) the user's currently-running charging session.
  ///
  /// Mirrors [loadHistory]: guests have no server session, so we surface the
  /// "no active session" empty state instead of an Unauthorized failure.
  Future<void> loadLiveSession({bool showSpinner = true}) async {
    if (AppStorage.isGuest) {
      emit(state.copyWith(
        liveStatus: MyBookingsStatus.success,
        liveSession: const LiveSessionEntity.inactive(),
        clearLiveError: true,
      ));
      return;
    }

    if (showSpinner) {
      emit(state.copyWith(
        liveStatus: MyBookingsStatus.loading,
        clearLiveError: true,
      ));
    }

    final result = await _getLiveSessionUseCase(const NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          liveStatus: MyBookingsStatus.failure,
          liveError: failure.message,
        ),
      ),
      (session) => emit(
        state.copyWith(
          liveStatus: MyBookingsStatus.success,
          liveSession: session,
          clearLiveError: true,
        ),
      ),
    );
  }

  /// Loads (or reloads) the user's charging-session history.
  ///
  /// Mirrors [loadBookings]: guests have no server session so we surface the
  /// empty state instead of an Unauthorized failure.
  Future<void> loadHistory({bool showSpinner = true}) async {
    if (AppStorage.isGuest) {
      emit(state.copyWith(
        historyStatus: MyBookingsStatus.success,
        historySessions: const [],
        clearHistoryError: true,
      ));
      return;
    }

    if (showSpinner) {
      emit(state.copyWith(
        historyStatus: MyBookingsStatus.loading,
        clearHistoryError: true,
      ));
    }

    final result = await _getChargeSessionHistoryUseCase(const NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          historyStatus: MyBookingsStatus.failure,
          historyError: failure.message,
        ),
      ),
      (sessions) => emit(
        state.copyWith(
          historyStatus: MyBookingsStatus.success,
          historySessions: sessions,
          clearHistoryError: true,
        ),
      ),
    );
  }

  /// Loads (or reloads) the user's bookings.
  Future<void> loadBookings({bool showSpinner = true}) async {
    // Guests have no session, so the API would return Unauthorized. Surface the
    // normal empty states (no active/upcoming/history) instead of a failure.
    if (AppStorage.isGuest) {
      emit(state.copyWith(
        status: MyBookingsStatus.success,
        bookings: const [],
        clearError: true,
      ));
      return;
    }

    if (showSpinner) {
      emit(state.copyWith(status: MyBookingsStatus.loading, clearError: true));
    }

    final result = await _getMyBookingsUseCase(const NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: MyBookingsStatus.failure,
          error: failure.message,
        ),
      ),
      (bookings) => emit(
        state.copyWith(
          status: MyBookingsStatus.success,
          bookings: bookings,
          clearError: true,
        ),
      ),
    );
  }

  /// Cancels a booking, then refreshes the list silently.
  Future<BookingActionResult> cancelBooking(int bookingId) async {
    if (state.actionBookingId != null) {
      return (success: false, message: 'Please wait for the current action.');
    }
    emit(state.copyWith(actionBookingId: bookingId));

    final result =
        await _cancelBookingUseCase(CancelBookingParams(bookingId: bookingId));

    if (isClosed) return (success: false, message: 'Cancelled');
    return result.fold(
      (failure) {
        emit(state.copyWith(clearActionBookingId: true));
        return (success: false, message: failure.message);
      },
      (message) async {
        await loadBookings(showSpinner: false);
        if (!isClosed) emit(state.copyWith(clearActionBookingId: true));
        return (success: true, message: message);
      },
    );
  }

  /// Verifies a scanned charger QR against an approved booking.
  ///
  /// Returns the [VerifyQrResultEntity] for both a match and a wrong connector
  /// (only transport/auth/server errors come back as a [Failure]). On a
  /// confirmed mismatch the backend flags the booking disputed, so we refresh
  /// the list silently to reflect the new status.
  Future<Either<Failure, VerifyQrResultEntity>> verifyQr({
    required String bookingCode,
    required String chargePointId,
    required int connectorId,
  }) async {
    final result = await _verifyQrUseCase(
      VerifyQrParams(
        bookingCode: bookingCode,
        chargePointId: chargePointId,
        connectorId: connectorId,
      ),
    );

    if (isClosed) return result;
    result.fold(
      (_) {},
      (data) {
        if (!data.isMatch) loadBookings(showSpinner: false);
      },
    );
    return result;
  }

  /// Reschedules a booking to a new date/slot(s), then refreshes the list.
  /// [noOfSlots] is 1 (30 min) or 2 (1 hour on consecutive slots).
  Future<BookingActionResult> rescheduleBooking({
    required int bookingId,
    required int locationId,
    required String bookingDate,
    required String startTime,
    int noOfSlots = 1,
  }) async {
    if (state.actionBookingId != null) {
      return (success: false, message: 'Please wait for the current action.');
    }
    emit(state.copyWith(actionBookingId: bookingId));

    final result = await _rescheduleBookingUseCase(
      RescheduleBookingParams(
        bookingId: bookingId,
        bookingDate: bookingDate,
        startTime: startTime,
        location: locationId,
        noOfSlots: noOfSlots,
      ),
    );

    if (isClosed) return (success: false, message: 'Rescheduled');
    return result.fold(
      (failure) {
        emit(state.copyWith(clearActionBookingId: true));
        return (success: false, message: failure.message);
      },
      (_) async {
        await loadBookings(showSpinner: false);
        if (!isClosed) emit(state.copyWith(clearActionBookingId: true));
        return (success: true, message: 'Booking rescheduled.');
      },
    );
  }
}

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/booking/domain/usecases/cancel_booking_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_charge_session_history_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_live_session_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_my_bookings_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/reschedule_booking_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/verify_qr_usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/verify_qr_result_entity.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';
import 'package:orko_hubco/features/booking/presentation/utils/live_session_completion.dart';

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

  /// Polls the live-session endpoint while the Active (Live) tab is on screen,
  /// so a session that starts (e.g. a walk-in) shows up within one interval
  /// even when the tab was sitting on the empty state.
  static const Duration _livePollInterval = Duration(seconds: 10);
  Timer? _liveTimer;

  /// Guards against overlapping live-session requests (a slow request must not
  /// let the next tick pile a second one on top of it).
  bool _liveInFlight = false;

  /// Starts (or keeps) the 10s live-session poll loop. Fires an immediate
  /// refresh — with a spinner only on the first load — then ticks silently.
  /// Safe to call repeatedly: it won't stack timers.
  void startLiveSessionPolling() {
    if (_liveTimer != null) return;
    loadLiveSession(
      showSpinner: state.liveStatus != MyBookingsStatus.success,
    );
    _liveTimer = Timer.periodic(
      _livePollInterval,
      (_) => loadLiveSession(showSpinner: false),
    );
  }

  /// Stops the live-session poll loop (tab left, screen backgrounded, or the
  /// cubit is closing).
  void stopLiveSessionPolling() {
    _liveTimer?.cancel();
    _liveTimer = null;
  }

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
    // Poll the live session for as long as the Active tab is open — with a
    // spinner on the first visit, silently on refreshes. Any other tab stops
    // the loop.
    if (tab == BookingTab.active) {
      startLiveSessionPolling();
    } else {
      stopLiveSessionPolling();
    }
    // Load charging history the first time History is opened, and refresh it
    // silently on subsequent visits. Also refresh the bookings list, since the
    // History tab now shows cancelled / no-show bookings alongside sessions.
    if (tab == BookingTab.history) {
      loadHistory(
        showSpinner: state.historyStatus != MyBookingsStatus.success,
      );
      loadBookings(showSpinner: false);
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

    // Don't let a slow request overlap with the next poll tick (or a manual
    // refresh landing on top of a poll already in flight).
    if (_liveInFlight) return;
    _liveInFlight = true;

    if (showSpinner) {
      emit(state.copyWith(
        liveStatus: MyBookingsStatus.loading,
        clearLiveError: true,
      ));
    }

    try {
      final result = await _getLiveSessionUseCase(const NoParams());

      if (isClosed) return;
      result.fold(
        (failure) {
          // A background poll that fails shouldn't blow away good data the user
          // is already looking at — only surface a failure when we have nothing
          // to show yet.
          if (state.liveStatus != MyBookingsStatus.success) {
            emit(
              state.copyWith(
                liveStatus: MyBookingsStatus.failure,
                liveError: failure.message,
              ),
            );
          }
        },
        (session) {
          // Persist the running session's id / detect that a previously-seen
          // session (this launch or an earlier, killed one) has finished.
          final completedId = LiveSessionCompletion.register(session);
          emit(
            state.copyWith(
              liveStatus: MyBookingsStatus.success,
              liveSession: session,
              clearLiveError: true,
              completedSessionId: completedId,
              clearCompletedSessionId: completedId == null,
            ),
          );
        },
      );
    } finally {
      _liveInFlight = false;
    }
  }

  /// Clears the one-shot [MyBookingsState.completedSessionId] once the view
  /// has reacted to it, so re-detection on a later load can fire the listener
  /// again if the summary couldn't be shown this time.
  void consumeSessionCompletion() {
    if (state.completedSessionId == null) return;
    emit(state.copyWith(clearCompletedSessionId: true));
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
          historySessions: _mostRecentSessions(sessions),
          clearHistoryError: true,
        ),
      ),
    );
  }

  /// The History tab shows at most this many charging sessions.
  static const int _maxHistorySessions = 10;

  /// Sorts [sessions] newest-first by `startedAt` (unparseable/missing dates
  /// last) and keeps only the [_maxHistorySessions] most recent, so the tab
  /// shows the 10 latest sessions regardless of the order the API returns.
  List<ChargeSessionHistoryEntity> _mostRecentSessions(
    List<ChargeSessionHistoryEntity> sessions,
  ) {
    DateTime? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    }

    final sorted = [...sessions]..sort((a, b) {
        final dateA = parse(a.startedAt);
        final dateB = parse(b.startedAt);
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return 1;
        if (dateB == null) return -1;
        return dateB.compareTo(dateA);
      });
    return sorted.take(_maxHistorySessions).toList();
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

  @override
  Future<void> close() {
    stopLiveSessionPolling();
    return super.close();
  }
}

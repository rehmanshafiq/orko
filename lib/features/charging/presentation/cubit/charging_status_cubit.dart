import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_live_session_usecase.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';

/// Drives the live charging-status screen.
///
/// The screen must reflect near-real-time telemetry, so the cubit polls
/// `GET api/v1/bookings/live-session/` on a fixed interval. A plain
/// [Timer.periodic] is the right tool here — the work is async network I/O
/// (already off the UI thread via Dio), so an isolate would add overhead and
/// inter-isolate messaging for no gain. Performance is protected by:
///   • polling silently (no spinner) so the screen never flickers,
///   • Equatable state so an unchanged payload triggers no rebuild,
///   • skipping a tick while a request is still in flight (no pile-up),
///   • pausing entirely when the screen is backgrounded (see [pause]).
class ChargingStatusCubit extends Cubit<ChargingStatusState> {
  ChargingStatusCubit({required GetLiveSessionUseCase getLiveSessionUseCase})
      : _getLiveSessionUseCase = getLiveSessionUseCase,
        super(ChargingStatusState.initial());

  final GetLiveSessionUseCase _getLiveSessionUseCase;

  static const Duration _pollInterval = Duration(seconds: 10);

  Timer? _timer;
  bool _inFlight = false;

  /// Kicks off the first load (with a spinner) and starts the poll loop.
  /// Safe to call more than once — it won't stack timers.
  void start() {
    if (_timer != null) return;
    _fetch(showSpinner: true);
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(_pollInterval, (_) => _fetch());
  }

  /// Pauses polling while the screen is not visible (e.g. app backgrounded),
  /// to avoid draining battery/data on a screen the user can't see.
  void pause() {
    _timer?.cancel();
    _timer = null;
  }

  /// Resumes polling after a [pause]: refresh once immediately, then resume the
  /// interval. No-op if already running.
  void resume() {
    if (_timer != null) return;
    _fetch();
    _startTimer();
  }

  /// Manual retry from the failure state, with a spinner.
  Future<void> retry() => _fetch(showSpinner: true);

  Future<void> _fetch({bool showSpinner = false}) async {
    // Guests have no server session — surface the empty/inactive state rather
    // than an Unauthorized failure, mirroring MyBookingsCubit.
    if (AppStorage.isGuest) {
      if (isClosed) return;
      emit(state.copyWith(
        status: ChargingStatusViewStatus.success,
        session: const LiveSessionEntity.inactive(),
        clearError: true,
      ));
      return;
    }

    // Don't let a slow request overlap with the next tick.
    if (_inFlight) return;
    _inFlight = true;

    if (showSpinner) {
      emit(state.copyWith(
        status: ChargingStatusViewStatus.loading,
        clearError: true,
      ));
    }

    try {
      final result = await _getLiveSessionUseCase(const NoParams());
      if (isClosed) return;
      result.fold(
        (failure) {
          // A background poll that fails shouldn't blow away good data the
          // user is already looking at — only surface a failure screen when we
          // have nothing to show yet.
          if (state.session == null) {
            emit(state.copyWith(
              status: ChargingStatusViewStatus.failure,
              error: failure.message,
            ));
          }
        },
        (session) => emit(state.copyWith(
          status: ChargingStatusViewStatus.success,
          session: session,
          clearError: true,
        )),
      );
    } finally {
      _inFlight = false;
    }
  }

  void updateProgress(double value) {
    emit(state.copyWith(sliderValue: value.clamp(0.0, 1.0)));
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _timer = null;
    return super.close();
  }
}

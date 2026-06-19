import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/booking/domain/usecases/cancel_booking_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_my_bookings_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/reschedule_booking_usecase.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

/// Outcome of a cancel/reschedule action, surfaced to the view for snackbars.
typedef BookingActionResult = ({bool success, String message});

class MyBookingsCubit extends Cubit<MyBookingsState> {
  MyBookingsCubit({
    required GetMyBookingsUseCase getMyBookingsUseCase,
    required CancelBookingUseCase cancelBookingUseCase,
    required RescheduleBookingUseCase rescheduleBookingUseCase,
  })  : _getMyBookingsUseCase = getMyBookingsUseCase,
        _cancelBookingUseCase = cancelBookingUseCase,
        _rescheduleBookingUseCase = rescheduleBookingUseCase,
        super(const MyBookingsState());

  final GetMyBookingsUseCase _getMyBookingsUseCase;
  final CancelBookingUseCase _cancelBookingUseCase;
  final RescheduleBookingUseCase _rescheduleBookingUseCase;

  void selectTab(BookingTab tab) {
    if (tab == state.selectedTab) return;
    emit(state.copyWith(selectedTab: tab));
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

  /// Reschedules a booking to a new date/slot, then refreshes the list.
  Future<BookingActionResult> rescheduleBooking({
    required int bookingId,
    required int locationId,
    required String bookingDate,
    required String startTime,
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

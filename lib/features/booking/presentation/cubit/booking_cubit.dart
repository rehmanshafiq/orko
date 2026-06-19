import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/domain/usecases/create_booking_hgl_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_booking_slots_usecase.dart';
import 'package:orko_hubco/features/booking/domain/usecases/get_charger_details_usecase.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_state.dart';

class BookingCubit extends Cubit<BookingState> {
  BookingCubit({
    required GetChargerDetailsUseCase getChargerDetailsUseCase,
    required GetBookingSlotsUseCase getSlotsUseCase,
    required CreateBookingHglUseCase createBookingUseCase,
  })  : _getChargerDetailsUseCase = getChargerDetailsUseCase,
        _getSlotsUseCase = getSlotsUseCase,
        _createBookingUseCase = createBookingUseCase,
        super(const BookingState());

  final GetChargerDetailsUseCase _getChargerDetailsUseCase;
  final GetBookingSlotsUseCase _getSlotsUseCase;
  // Booking uses the `book-charge-session` endpoint: end_time is auto-derived
  // by the backend (start + 30 min), so it must NOT be sent.
  final CreateBookingHglUseCase _createBookingUseCase;

  static const int minDuration = 1;
  static const int maxDuration = 8;

  /// How many days to surface in the date strip (today + following days).
  static const int _dateOptionCount = 7;

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// Seeds the screen with the station context and loads today's slots.
  void start({
    required int? locationId,
    String? stationName,
    String? stationAddress,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final options = List<DateTime>.generate(
      _dateOptionCount,
      (i) => today.add(Duration(days: i)),
    );
    emit(
      state.copyWith(
        locationId: locationId,
        stationName: stationName,
        stationAddress: stationAddress,
        dateOptions: options,
        selectedDateIndex: 0,
        clearSelectedSlot: true,
      ),
    );
    loadChargerDetails();
    loadSlots();
  }

  /// Fetches the location's charger/connector list and station info.
  Future<void> loadChargerDetails() async {
    final locationId = state.locationId;
    if (locationId == null) {
      emit(
        state.copyWith(
          chargerStatus: ChargerStatus.failure,
          ports: const [],
          chargerError: 'Location unavailable. Please reopen this station.',
        ),
      );
      return;
    }

    emit(state.copyWith(chargerStatus: ChargerStatus.loading, clearChargerError: true));

    final result = await _getChargerDetailsUseCase(
      GetChargerDetailsParams(locationId: locationId),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          chargerStatus: ChargerStatus.failure,
          ports: const [],
          chargerError: failure.message,
        ),
      ),
      (details) {
        // Default-select the first available connector for display.
        int? firstAvailable;
        for (final p in details.ports) {
          if (p.isAvailable) {
            firstAvailable = p.id;
            break;
          }
        }
        emit(
          state.copyWith(
            chargerStatus: ChargerStatus.success,
            ports: details.ports,
            stationName: details.stationName.isNotEmpty
                ? details.stationName
                : state.stationName,
            stationAddress: details.stationAddress.isNotEmpty
                ? details.stationAddress
                : state.stationAddress,
            selectedPortId: firstAvailable,
            clearSelectedPort: firstAvailable == null,
          ),
        );
      },
    );
  }

  /// Fetches slots for the currently selected date + location.
  Future<void> loadSlots() async {
    final locationId = state.locationId;
    if (locationId == null) {
      emit(
        state.copyWith(
          slotsStatus: SlotsStatus.failure,
          slots: const [],
          slotsError: 'Location unavailable. Please reopen this station.',
        ),
      );
      return;
    }
    final date = state.selectedDate;
    if (date == null) return;

    emit(
      state.copyWith(
        slotsStatus: SlotsStatus.loading,
        clearSlotsError: true,
        clearSelectedSlot: true,
      ),
    );

    final result = await _getSlotsUseCase(
      GetBookingSlotsParams(date: _apiDate.format(date), locationId: locationId),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(
          slotsStatus: SlotsStatus.failure,
          slots: const [],
          slotsError: failure.message,
        ),
      ),
      (slots) => emit(
        state.copyWith(slotsStatus: SlotsStatus.success, slots: slots),
      ),
    );
  }

  void selectDate(int index) {
    if (index == state.selectedDateIndex) return;
    if (index < 0 || index >= state.dateOptions.length) return;
    emit(state.copyWith(selectedDateIndex: index, clearSelectedSlot: true));
    loadSlots();
  }

  /// Selects (or toggles off) an available slot.
  void selectSlot(BookingSlotEntity slot) {
    if (!slot.isAvailable) return;
    final isSame = state.selectedSlot?.startTime == slot.startTime;
    if (isSame) {
      emit(state.copyWith(clearSelectedSlot: true, clearSubmitError: true));
    } else {
      emit(state.copyWith(selectedSlot: slot, clearSubmitError: true));
    }
  }

  /// Creates the booking for the selected slot via the primary endpoint.
  /// Returns `true` on success so the view can navigate.
  Future<bool> submitBooking() async {
    final slot = state.selectedSlot;
    final locationId = state.locationId;
    if (slot == null || locationId == null || state.isSubmitting) return false;
    final date = state.selectedDate;
    if (date == null) return false;

    emit(
      state.copyWith(
        submitStatus: BookingSubmitStatus.submitting,
        clearSubmitError: true,
      ),
    );

    final result = await _createBookingUseCase(
      CreateBookingHglParams(
        bookingDate: _apiDate.format(date),
        startTime: slot.startTime,
        location: locationId,
      ),
    );

    if (isClosed) return false;
    return result.fold(
      (failure) {
        emit(
          state.copyWith(
            submitStatus: BookingSubmitStatus.failure,
            submitError: failure.message,
          ),
        );
        return false;
      },
      (booking) {
        emit(
          state.copyWith(
            submitStatus: BookingSubmitStatus.success,
            createdBooking: booking,
          ),
        );
        return true;
      },
    );
  }

  /// Highlights an available connector. Display-only — the booking endpoint
  /// auto-assigns the actual connector.
  void selectPort(int portId) {
    final port = state.ports.where((p) => p.id == portId);
    if (port.isEmpty || !port.first.isAvailable) return;
    emit(state.copyWith(selectedPortId: portId));
  }

  // ── Cosmetic-only selector (no effect on the booking payload) ───────────

  void increaseDuration() {
    if (state.durationHours >= maxDuration) return;
    emit(state.copyWith(durationHours: state.durationHours + 1));
  }

  void decreaseDuration() {
    if (state.durationHours <= minDuration) return;
    emit(state.copyWith(durationHours: state.durationHours - 1));
  }
}

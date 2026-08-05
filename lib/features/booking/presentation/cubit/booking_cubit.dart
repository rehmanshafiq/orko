import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
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
    required AnalyticsService analytics,
  })  : _getChargerDetailsUseCase = getChargerDetailsUseCase,
        _getSlotsUseCase = getSlotsUseCase,
        _createBookingUseCase = createBookingUseCase,
        _analytics = analytics,
        super(const BookingState());

  final GetChargerDetailsUseCase _getChargerDetailsUseCase;
  final GetBookingSlotsUseCase _getSlotsUseCase;
  final AnalyticsService _analytics;
  // Booking uses the `book-charge-session` endpoint: end_time is auto-derived
  // by the backend (start + 30 min), so it must NOT be sent.
  final CreateBookingHglUseCase _createBookingUseCase;

  /// The API books 30-min slots and supports at most 2 consecutive slots
  /// (a 1-hour booking) reserved atomically on one connector.
  static const int maxSlotsPerBooking = 2;

  /// How many days to surface in the date strip (today + following days).
  static const int _dateOptionCount = 7;

  static final DateFormat _apiDate = DateFormat('yyyy-MM-dd');

  /// Seeds the screen with the station context and loads today's slots.
  void start({
    required int? locationId,
    int? vehicleId,
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
        vehicleId: vehicleId,
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

  /// Selects/deselects an available 30-min slot, allowing up to
  /// [maxSlotsPerBooking] *consecutive* slots (the API only books adjacent
  /// slots on one connector).
  ///
  /// Rules:
  /// * tap a selected slot → it's removed from the selection;
  /// * tap a slot adjacent to the current selection (and room remains) → added;
  /// * anything else (non-adjacent, or selection already full) → the selection
  ///   restarts from the tapped slot.
  void selectSlot(BookingSlotEntity slot) {
    if (!slot.isAvailable) return;

    final current = List<BookingSlotEntity>.from(state.selectedSlots);
    final alreadyIndex =
        current.indexWhere((s) => s.startTime == slot.startTime);

    List<BookingSlotEntity> next;
    if (alreadyIndex >= 0) {
      // Toggle off just that slot; whatever remains is still valid.
      current.removeAt(alreadyIndex);
      next = current;
    } else if (current.isEmpty) {
      next = [slot];
    } else if (current.length < maxSlotsPerBooking &&
        _isAdjacentToSelection(current, slot)) {
      next = [...current, slot]
        ..sort((a, b) => _minutes(a.startTime).compareTo(_minutes(b.startTime)));
    } else {
      // Non-consecutive tap or selection already full → start over from here.
      next = [slot];
    }

    emit(state.copyWith(selectedSlots: next, clearSubmitError: true));
  }

  /// True when [slot] directly precedes or follows the selected block.
  bool _isAdjacentToSelection(
    List<BookingSlotEntity> selection,
    BookingSlotEntity slot,
  ) {
    final first = selection.first;
    final last = selection.last;
    final slotStart = _minutes(slot.startTime);
    final slotEnd = _minutes(slot.endTime);
    if (slotStart < 0 || slotEnd < 0) return false;
    return slotStart == _minutes(last.endTime) ||
        slotEnd == _minutes(first.startTime);
  }

  /// Parses `HH:mm` to minutes-since-midnight; -1 when unparseable (never
  /// matches an adjacency check).
  static int _minutes(String time) {
    final parts = time.split(':');
    if (parts.length < 2) return -1;
    final h = int.tryParse(parts[0].trim());
    final m = int.tryParse(parts[1].trim());
    if (h == null || m == null) return -1;
    return h * 60 + m;
  }

  /// Creates the booking for the selected slot(s) via the primary endpoint.
  /// `start_time` is the first slot's start; `no_of_slots` covers the rest.
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
        vehicleId: state.vehicleId,
        noOfSlots: state.noOfSlots,
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
        // Estimated amount mirrors the booking-success screen's calculation
        // (price_per_kwh × 5 × no_of_slots); labelled est_* since real revenue
        // is only realized at charging_session_completed.
        final pricePerKwh = state.selectedPort?.price?.price ?? 0;
        final estAmount = (pricePerKwh * 5 * state.noOfSlots).round();
        _analytics.logEvent(
          'booking_submitted',
          parameters: {
            'booking_id': booking.id,
            'station_id': state.locationId,
            'no_of_slots': state.noOfSlots,
            'est_amount': estAmount,
            'vehicle_id': state.vehicleId,
          },
        );
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
}

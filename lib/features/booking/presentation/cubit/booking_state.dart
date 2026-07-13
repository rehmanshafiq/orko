import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/booking_slot_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/charger_details_entity.dart';

/// Lifecycle of the charger-details fetch.
enum ChargerStatus { initial, loading, success, failure }

/// Lifecycle of the slots-fetch for the currently selected date.
enum SlotsStatus { initial, loading, success, failure }

/// Lifecycle of the create-booking request.
enum BookingSubmitStatus { idle, submitting, success, failure }

class BookingState extends Equatable {
  const BookingState({
    this.locationId,
    this.vehicleId,
    this.stationName,
    this.stationAddress,
    this.chargerStatus = ChargerStatus.initial,
    this.ports = const [],
    this.chargerError,
    this.selectedPortId,
    this.dateOptions = const [],
    this.selectedDateIndex = 0,
    this.slotsStatus = SlotsStatus.initial,
    this.slots = const [],
    this.slotsError,
    this.selectedSlots = const [],
    this.submitStatus = BookingSubmitStatus.idle,
    this.submitError,
    this.createdBooking,
  });

  /// Charging location id required by every booking call. Null when the screen
  /// was opened without a station (legacy navigation) → booking is disabled.
  final int? locationId;

  /// User vehicle resolved by the compatibility gate; sent as `vehicle_id` in
  /// the create-booking request. Null when the screen is opened without a
  /// resolved vehicle (e.g. trip planner) → `vehicle_id` is omitted.
  final int? vehicleId;
  final String? stationName;
  final String? stationAddress;

  /// Charger-details (connectors) lifecycle + data for this location.
  final ChargerStatus chargerStatus;
  final List<ChargerPortEntity> ports;
  final String? chargerError;

  /// Currently highlighted connector id (display-only; the booking endpoint
  /// auto-assigns the connector).
  final int? selectedPortId;

  /// Selectable dates, starting today. Only today + the next day fall inside the
  /// API's 24-hour window; later dates are shown but rejected server-side.
  final List<DateTime> dateOptions;
  final int selectedDateIndex;

  final SlotsStatus slotsStatus;
  final List<BookingSlotEntity> slots;
  final String? slotsError;

  /// The slots the user tapped, kept sorted by start time. Up to 2 consecutive
  /// 30-min slots (2 = a 1-hour booking); the API only supports adjacent slots.
  final List<BookingSlotEntity> selectedSlots;

  final BookingSubmitStatus submitStatus;
  final String? submitError;
  final BookingEntity? createdBooking;

  /// First selected slot — the booking's `start_time` source.
  BookingSlotEntity? get selectedSlot =>
      selectedSlots.isEmpty ? null : selectedSlots.first;

  /// Last selected slot — supplies the display end time.
  BookingSlotEntity? get lastSelectedSlot =>
      selectedSlots.isEmpty ? null : selectedSlots.last;

  /// `no_of_slots` for the booking request (1 or 2).
  int get noOfSlots => selectedSlots.isEmpty ? 1 : selectedSlots.length;

  /// Total booked duration in minutes (each slot is 30 min).
  int get bookingMinutes => 30 * noOfSlots;

  /// The currently highlighted connector, if any.
  ChargerPortEntity? get selectedPort {
    for (final p in ports) {
      if (p.id == selectedPortId) return p;
    }
    return null;
  }

  bool get hasAvailablePort => ports.any((p) => p.isAvailable);

  DateTime? get selectedDate =>
      (selectedDateIndex >= 0 && selectedDateIndex < dateOptions.length)
          ? dateOptions[selectedDateIndex]
          : null;

  bool get hasAvailableSlots =>
      slots.any((s) => s.isAvailable);

  bool get isSubmitting => submitStatus == BookingSubmitStatus.submitting;

  bool get canContinue =>
      selectedSlots.isNotEmpty && locationId != null && !isSubmitting;

  BookingState copyWith({
    int? locationId,
    int? vehicleId,
    String? stationName,
    String? stationAddress,
    ChargerStatus? chargerStatus,
    List<ChargerPortEntity>? ports,
    String? chargerError,
    bool clearChargerError = false,
    int? selectedPortId,
    bool clearSelectedPort = false,
    List<DateTime>? dateOptions,
    int? selectedDateIndex,
    SlotsStatus? slotsStatus,
    List<BookingSlotEntity>? slots,
    String? slotsError,
    bool clearSlotsError = false,
    List<BookingSlotEntity>? selectedSlots,
    bool clearSelectedSlot = false,
    BookingSubmitStatus? submitStatus,
    String? submitError,
    bool clearSubmitError = false,
    BookingEntity? createdBooking,
  }) {
    return BookingState(
      locationId: locationId ?? this.locationId,
      vehicleId: vehicleId ?? this.vehicleId,
      stationName: stationName ?? this.stationName,
      stationAddress: stationAddress ?? this.stationAddress,
      chargerStatus: chargerStatus ?? this.chargerStatus,
      ports: ports ?? this.ports,
      chargerError:
          clearChargerError ? null : (chargerError ?? this.chargerError),
      selectedPortId:
          clearSelectedPort ? null : (selectedPortId ?? this.selectedPortId),
      dateOptions: dateOptions ?? this.dateOptions,
      selectedDateIndex: selectedDateIndex ?? this.selectedDateIndex,
      slotsStatus: slotsStatus ?? this.slotsStatus,
      slots: slots ?? this.slots,
      slotsError: clearSlotsError ? null : (slotsError ?? this.slotsError),
      selectedSlots:
          clearSelectedSlot ? const [] : (selectedSlots ?? this.selectedSlots),
      submitStatus: submitStatus ?? this.submitStatus,
      submitError: clearSubmitError ? null : (submitError ?? this.submitError),
      createdBooking: createdBooking ?? this.createdBooking,
    );
  }

  @override
  List<Object?> get props => [
        locationId,
        vehicleId,
        stationName,
        stationAddress,
        chargerStatus,
        ports,
        chargerError,
        selectedPortId,
        dateOptions,
        selectedDateIndex,
        slotsStatus,
        slots,
        slotsError,
        selectedSlots,
        submitStatus,
        submitError,
        createdBooking,
      ];
}

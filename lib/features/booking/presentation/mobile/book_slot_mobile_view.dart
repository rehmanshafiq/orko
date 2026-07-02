import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/booking/presentation/booked_stations_session.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_state.dart';
import 'package:orko_hubco/features/booking/presentation/pages/booking_success_page.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/charger_port_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/date_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/duration_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/station_info_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/summary_bottom_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/time_slot_grid.dart';

/// EV charging slot booking UI backed by the bookings API.
class BookSlotMobileView extends StatelessWidget {
  const BookSlotMobileView({
    super.key,
    this.stationName,
    this.stationAddress,
    this.fromTrip = false,
  });

  final String? stationName;
  final String? stationAddress;

  /// True when opened from the Trip planner's Pre-book flow — forwarded to the
  /// booking success screen so its close button returns to the Trip planner.
  final bool fromTrip;

  static const String _defaultStationTitle = 'HGL Charging Hub Motorway M2';
  static const String _defaultStationAddress =
      'Motorway M2, Near Exit 15, XYZ City';

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppUtils.horizontal16Padding,
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: ui.textPrimary, size: 20.sp),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  Expanded(
                    child: AppText(
                      'Book a Slot',
                      textAlign: TextAlign.center,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font18Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
                  40.horizontalSpace,
                ],
              ),
            ),
            Expanded(
              child: BlocConsumer<BookingCubit, BookingState>(
                listenWhen: (prev, curr) =>
                    prev.submitStatus != curr.submitStatus,
                listener: _onSubmitStatusChanged,
                builder: (context, state) {
                  final cubit = context.read<BookingCubit>();
                  final screenW = MediaQuery.sizeOf(context).width;
                  final buttonW = screenW - 32.w - 24.w;
                  // Estimated energy uses a flat ~10 kWh/hour assumption; cost
                  // is driven by the selected connector's per-kWh tariff.
                  final selectedPrice = state.selectedPort?.price;
                  final pricePerKwh = selectedPrice?.price ?? 0;
                  final currency = (selectedPrice?.currency.isNotEmpty ?? false)
                      ? selectedPrice!.currency
                      : 'PKR';
                  final kwhNote = 10 * state.durationHours;
                  final estimated = pricePerKwh * kwhNote;
                  final hasPrice = selectedPrice != null && pricePerKwh > 0;

                  return SingleChildScrollView(
                    padding: AppUtils.horizontal16Padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        16.verticalSpace,
                        StationInfoCard(
                          title: state.stationName ??
                              stationName ??
                              _defaultStationTitle,
                          address: state.stationAddress ??
                              stationAddress ??
                              _defaultStationAddress,
                          ui: ui,
                          // Plug chips mirror each port's connectorType.
                          connectorTypes: state.ports
                              .map((p) => p.connectorType.trim())
                              .where((t) => t.isNotEmpty)
                              .toSet()
                              .toList(),
                        ),
                        20.verticalSpace,
                        AppText(
                          'Select Charger Port',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        _ChargerSection(ui: ui, state: state, cubit: cubit),
                        20.verticalSpace,
                        AppText(
                          'Select Date',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        DateSelector(
                          ui: ui,
                          dateOptions: state.dateOptions,
                          selectedIndex: state.selectedDateIndex,
                          onSelectDate: cubit.selectDate,
                        ),
                        20.verticalSpace,
                        AppText(
                          'Available Time Slots',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        12.verticalSpace,
                        _SlotsSection(ui: ui, state: state, cubit: cubit),
                        20.verticalSpace,
                        DurationSelector(
                          ui: ui,
                          durationHours: state.durationHours,
                          minDurationHours: BookingCubit.minDuration,
                          maxDurationHours: BookingCubit.maxDuration,
                          onDecrease: cubit.decreaseDuration,
                          onIncrease: cubit.increaseDuration,
                        ),
                        18.verticalSpace,
                        SummaryBottomCard(
                          ui: ui,
                          durationHours: state.durationHours,
                          estimatedCost: estimated,
                          estimatedKwh: kwhNote,
                          currency: currency,
                          pricePerKwh: pricePerKwh,
                          hasPrice: hasPrice,
                          buttonWidth: buttonW,
                          isContinueEnabled: state.canContinue,
                          onContinueToPayment: () => _onContinue(context, cubit),
                        ),
                        16.verticalSpace,
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onContinue(BuildContext context, BookingCubit cubit) {
    // Guests can browse and select a slot but must authenticate before booking.
    if (AppStorage.isGuest) {
      AuthRequiredDialog.show(context);
      return;
    }
    // The vehicle is chosen earlier by the compatibility gate (station detail
    // screen) and arrives here as `state.vehicleId`, which submitBooking sends
    // as `vehicle_id`. No vehicle picker is shown on this screen.
    cubit.submitBooking();
  }

  void _onSubmitStatusChanged(BuildContext context, BookingState state) {
    final messenger = ScaffoldMessenger.of(context);
    switch (state.submitStatus) {
      case BookingSubmitStatus.success:
        // messenger.showSnackBar(
        //   const SnackBar(
        //     content: Text('Booking requested — pending approval.'),
        //     behavior: SnackBarBehavior.floating,
        //   ),
        // );
        // Remember the booked station so the trip planner can flip that
        // stop's "Pre-book" button to "Booked". Only reached on a confirmed
        // create-booking success, so a mere visit never marks anything.
        final bookedLocationId = state.locationId;
        if (bookedLocationId != null) {
          BookedStationsSession.markBooked(bookedLocationId);
        }
        final pricePerKwh = state.selectedPort?.price?.price ?? 0;
        final amount = (pricePerKwh * 10 * state.durationHours).round();
        context.push(
          '/booking-success',
          extra: BookingSuccessArgs(
            bookingRef: _bookingRef(state),
            stationName: state.stationName ?? stationName ?? _defaultStationTitle,
            slotLabel: _slotLabel(state),
            amountPaid: amount,
            fromTrip: fromTrip,
          ),
        );
        break;
      case BookingSubmitStatus.failure:
        messenger.showSnackBar(
          SnackBar(
            content: Text(state.submitError ?? 'Booking failed. Try again.'),
            backgroundColor: AppColors.removeColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        break;
      case BookingSubmitStatus.idle:
      case BookingSubmitStatus.submitting:
        break;
    }
  }

  /// Builds a human-readable booking reference from the created booking id.
  String _bookingRef(BookingState state) {
    final id = state.createdBooking?.id;
    return id == null ? '—' : 'BK-$id';
  }

  /// Builds the slot label, e.g. `April 18 · 14:00 – 15:00`.
  ///
  /// Prefers the confirmed booking, but falls back to the slot/date the user
  /// selected on this screen whenever the create response omits those fields.
  /// The create-booking model parses missing values as empty strings (not
  /// null), so empties are treated as missing here.
  String _slotLabel(BookingState state) {
    final booking = state.createdBooking;

    final bookingDate = (booking?.bookingDate ?? '').trim();
    final date = bookingDate.isNotEmpty
        ? DateTime.tryParse(bookingDate)
        : state.selectedDate;

    var start = (booking?.startTime ?? '').trim();
    if (start.isEmpty) start = state.selectedSlot?.startTime ?? '';

    var end = (booking?.endTime ?? '').trim();
    if (end.isEmpty) {
      end = state.selectedSlot != null && state.durationHours <= 1
          ? state.selectedSlot!.endTime
          : _addHours(start, state.durationHours);
    }

    final dateLabel = date != null ? DateFormat('MMMM d').format(date) : '';
    final timeLabel = [start, end].where((t) => t.isNotEmpty).join(' – ');

    return [dateLabel, timeLabel].where((p) => p.isNotEmpty).join(' · ');
  }

  /// Adds [hours] to an `HH:mm` time string, wrapping past midnight. Returns an
  /// empty string when [time] can't be parsed.
  String _addHours(String time, int hours) {
    final parts = time.split(':');
    if (parts.length < 2) return '';
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null) return '';
    final total = (h * 60 + m + hours * 60) % (24 * 60);
    final endH = (total ~/ 60).toString().padLeft(2, '0');
    final endM = (total % 60).toString().padLeft(2, '0');
    return '$endH:$endM';
  }
}

/// Renders the charger/connector selector depending on the fetch lifecycle.
class _ChargerSection extends StatelessWidget {
  const _ChargerSection({
    required this.ui,
    required this.state,
    required this.cubit,
  });

  final AppUiColors ui;
  final BookingState state;
  final BookingCubit cubit;

  @override
  Widget build(BuildContext context) {
    switch (state.chargerStatus) {
      case ChargerStatus.initial:
      case ChargerStatus.loading:
        return SizedBox(
          height: 148.h,
          child: Center(
            child: SizedBox(
              width: 26.w,
              height: 26.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: ui.brandPrimary,
              ),
            ),
          ),
        );

      case ChargerStatus.failure:
        return _SlotsMessage(
          ui: ui,
          message: state.chargerError ?? 'Could not load chargers.',
          onRetry: state.locationId == null ? null : cubit.loadChargerDetails,
        );

      case ChargerStatus.success:
        if (state.ports.isEmpty) {
          return _SlotsMessage(
            ui: ui,
            message: 'No connectors at this station.',
            onRetry: cubit.loadChargerDetails,
          );
        }
        return ChargerPortSelector(
          ui: ui,
          ports: state.ports,
          selectedPortId: state.selectedPortId,
        );
    }
  }
}

/// Renders the slots area depending on the fetch lifecycle.
class _SlotsSection extends StatelessWidget {
  const _SlotsSection({
    required this.ui,
    required this.state,
    required this.cubit,
  });

  final AppUiColors ui;
  final BookingState state;
  final BookingCubit cubit;

  @override
  Widget build(BuildContext context) {
    switch (state.slotsStatus) {
      case SlotsStatus.initial:
      case SlotsStatus.loading:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Center(
            child: SizedBox(
              width: 26.w,
              height: 26.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: ui.brandPrimary,
              ),
            ),
          ),
        );

      case SlotsStatus.failure:
        return _SlotsMessage(
          ui: ui,
          message: state.slotsError ?? 'Could not load time slots.',
          onRetry: state.locationId == null ? null : cubit.loadSlots,
        );

      case SlotsStatus.success:
        // Only show available slots — hide booked/unavailable ones entirely.
        final availableSlots =
            state.slots.where((s) => s.isAvailable).toList(growable: false);
        if (state.slots.isEmpty) {
          return _SlotsMessage(
            ui: ui,
            message: 'No time slots for this date.',
            onRetry: cubit.loadSlots,
          );
        }
        if (availableSlots.isEmpty) {
          return _SlotsMessage(
            ui: ui,
            message: 'All slots are booked for this date.',
            onRetry: cubit.loadSlots,
          );
        }
        return TimeSlotGrid(
          ui: ui,
          slots: availableSlots,
          selectedStartTime: state.selectedSlot?.startTime,
          onSlotTap: cubit.selectSlot,
        );
    }
  }
}

class _SlotsMessage extends StatelessWidget {
  const _SlotsMessage({
    required this.ui,
    required this.message,
    this.onRetry,
  });

  final AppUiColors ui;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 18.h),
      decoration: BoxDecoration(
        color: ui.cardBookingBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        children: [
          AppText(
            message,
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font13Sp,
            fontWeight: FontWeights.weight500,
          ),
          if (onRetry != null) ...[
            10.verticalSpace,
            TextButton(
              onPressed: onRetry,
              child: AppText(
                'Retry',
                color: ui.brandPrimary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

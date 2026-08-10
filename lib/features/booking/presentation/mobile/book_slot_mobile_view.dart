import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/booking/presentation/booked_stations_session.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/booking_state.dart';
import 'package:orko_hubco/features/booking/presentation/pages/booking_success_page.dart';
import 'package:orko_hubco/features/booking/presentation/utils/operating_hours.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/charger_port_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/date_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/station_info_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/summary_bottom_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/time_slot_grid.dart';

/// EV charging slot booking UI backed by the bookings API.
class BookSlotMobileView extends StatefulWidget {
  const BookSlotMobileView({
    super.key,
    this.stationName,
    this.stationAddress,
    this.fromTrip = false,
    this.openingTime = '',
    this.closingTime = '',
  });

  final String? stationName;
  final String? stationAddress;

  /// True when opened from the Trip planner's Pre-book flow — forwarded to the
  /// booking success screen so its close button returns to the Trip planner.
  final bool fromTrip;

  /// Station opening time (`HH:mm:ss`) from station detail — used to grey out
  /// Available Time Slots that fall outside service hours.
  final String openingTime;

  /// Station closing time (`HH:mm:ss`) from station detail — used to grey out
  /// Available Time Slots that fall outside service hours.
  final String closingTime;

  @override
  State<BookSlotMobileView> createState() => _BookSlotMobileViewState();
}

class _BookSlotMobileViewState extends State<BookSlotMobileView> {
  static const String _defaultStationTitle = 'HGL Charging Hub Motorway M2';
  static const String _defaultStationAddress =
      'Motorway M2, Near Exit 15, XYZ City';

  @override
  void initState() {
    super.initState();
    // Booking-funnel entry: fires once when the Book-a-Slot screen opens. The
    // BookingCubit is created (and `start()`ed with the location) by BookSlotPage
    // above this widget, so its locationId is already populated here.
    final cubit = context.read<BookingCubit>();
    sl<AnalyticsService>().logEvent('book_slot_tapped', parameters: {
      'station_id': cubit.state.locationId,
      'is_guest': AppStorage.isGuest,
    });
  }

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

                  return SingleChildScrollView(
                    padding: AppUtils.horizontal16Padding,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        20.verticalSpace,
                        StationInfoCard(
                          title: state.stationName ??
                              widget.stationName ??
                              _defaultStationTitle,
                          address: state.stationAddress ??
                              widget.stationAddress ??
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
                        // AppText(
                        //   'Select Charger Port',
                        //   color: ui.textPrimary,
                        //   fontSize: FontSizes.font14Sp,
                        //   fontWeight: FontWeights.weight700,
                        // ),
                        // 12.verticalSpace,
                        // _ChargerSection(ui: ui, state: state, cubit: cubit),
                        // 20.verticalSpace,
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
                        22.verticalSpace,
                        AppText(
                          'Available Time Slots',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                        4.verticalSpace,
                        AppText(
                          'Each slot is 30 min — select 2 consecutive slots '
                          'for a 1-hour booking.',
                          color: ui.textSecondary,
                          fontSize: FontSizes.font11Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        20.verticalSpace,
                        _SlotsSection(
                          ui: ui,
                          state: state,
                          cubit: cubit,
                          operatingHours: OperatingHours(
                            openingTime: widget.openingTime,
                            closingTime: widget.closingTime,
                          ),
                        ),
                        24.verticalSpace,
                        SummaryBottomCard(
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
      AuthRequiredDialog.show(context, feature: 'booking');
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
        final amount = (pricePerKwh * 5 * state.noOfSlots).round();
        context.push(
          '/booking-success',
          extra: BookingSuccessArgs(
            bookingRef: _bookingRef(state),
            stationName:
                state.stationName ?? widget.stationName ?? _defaultStationTitle,
            slotLabel: _slotLabel(state),
            amountPaid: amount,
            fromTrip: widget.fromTrip,
            // Slot-release window from the backend config; display-only.
            minutesMobile: state.createdBooking?.minutesMobile,
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
  /// Prefers the confirmed booking, but falls back to the slots/date the user
  /// selected on this screen whenever the create response omits those fields
  /// (the create-booking model parses missing values as empty strings). The
  /// fallback end time is the last selected slot's end, covering both 30-min
  /// and 1-hour (two consecutive slots) bookings.
  String _slotLabel(BookingState state) {
    final booking = state.createdBooking;

    final bookingDate = (booking?.bookingDate ?? '').trim();
    final date = bookingDate.isNotEmpty
        ? DateTime.tryParse(bookingDate)
        : state.selectedDate;

    var start = (booking?.startTime ?? '').trim();
    if (start.isEmpty) start = state.selectedSlot?.startTime ?? '';

    var end = (booking?.endTime ?? '').trim();
    if (end.isEmpty) end = state.lastSelectedSlot?.endTime ?? '';

    final dateLabel = date != null ? DateFormat('MMMM d').format(date) : '';
    final timeLabel = [start, end].where((t) => t.isNotEmpty).join(' – ');

    return [dateLabel, timeLabel].where((p) => p.isNotEmpty).join(' · ');
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
    required this.operatingHours,
  });

  final AppUiColors ui;
  final BookingState state;
  final BookingCubit cubit;
  final OperatingHours operatingHours;

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
        // Only show available slots that fall within operating hours — hide
        // booked/unavailable slots and out-of-hours slots entirely.
        final availableSlots = state.slots
            .where((s) =>
                s.isAvailable &&
                operatingHours.containsSlot(
                  startTime: s.startTime,
                  endTime: s.endTime,
                ))
            .toList(growable: false);
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
          selectedStartTimes: {
            for (final s in state.selectedSlots) s.startTime,
          },
          isOutOfHours: (_) => false,
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/services/barcode_scanner_service.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/booking_empty_state.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/bookings_tab_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/history_booking_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/reschedule_sheet.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/upcoming_booking_card.dart';

class MyBookingsMobileView extends StatelessWidget {
  const MyBookingsMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            final cubit = context.read<MyBookingsCubit>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppUtils.horizontal16Padding.add(
                    EdgeInsets.only(top: 12.h, bottom: 4.h),
                  ),
                  child: AppText(
                    'My Bookings',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font22Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
                12.verticalSpace,
                Padding(
                  padding: AppUtils.horizontal16Padding,
                  child: BookingsTabSelector(
                    ui: ui,
                    selectedTab: state.selectedTab,
                    onTabSelected: cubit.selectTab,
                  ),
                ),
                16.verticalSpace,
                Expanded(
                  child: _Body(ui: ui, state: state, cubit: cubit),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.ui, required this.state, required this.cubit});

  final AppUiColors ui;
  final MyBookingsState state;
  final MyBookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    // The History tab is driven by its own endpoint/state, so it renders
    // independently of the my-bookings (Upcoming/Active) load status.
    if (state.selectedTab == BookingTab.history) {
      return _HistoryTab(ui: ui, state: state, cubit: cubit);
    }

    if (state.status == MyBookingsStatus.loading ||
        state.status == MyBookingsStatus.initial) {
      return Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: ui.brandPrimary,
          ),
        ),
      );
    }

    if (state.status == MyBookingsStatus.failure) {
      return ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          60.verticalSpace,
          Icon(Icons.error_outline_rounded,
              color: ui.textSecondary, size: 40.sp),
          12.verticalSpace,
          AppText(
            state.error ?? 'Could not load your bookings.',
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          16.verticalSpace,
          Center(
            child: SizedBox(
              width: 160.w,
              child: PrimaryButtonWidget(
                text: 'Retry',
                onPress: cubit.loadBookings,
                buttonHeight: 40.h,
                cornerRadius: 22.r,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      color: ui.brandPrimary,
      onRefresh: () => cubit.loadBookings(showSpinner: false),
      child: _TabContent(ui: ui, state: state, cubit: cubit),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.ui,
    required this.state,
    required this.cubit,
  });

  final AppUiColors ui;
  final MyBookingsState state;
  final MyBookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    switch (state.selectedTab) {
      case BookingTab.active:
        return _emptyList(
          icon: Icons.bolt,
          title: 'No Active Sessions',
          subtitle: "You don't have any active charging sessions",
        );
      case BookingTab.upcoming:
        return _UpcomingTab(ui: ui, state: state, cubit: cubit);
      case BookingTab.history:
        return _HistoryTab(ui: ui, state: state, cubit: cubit);
    }
  }

  Widget _emptyList({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return ListView(
      padding: AppUtils.horizontal16Padding,
      children: [
        BookingEmptyState(
          ui: ui,
          icon: icon,
          title: title,
          subtitle: subtitle,
          accentColor: ui.brandPrimary,
          iconOutlined: true,
        ),
      ],
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({
    required this.ui,
    required this.state,
    required this.cubit,
  });

  final AppUiColors ui;
  final MyBookingsState state;
  final MyBookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    final bookings = state.upcoming;
    if (bookings.isEmpty) {
      return ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          BookingEmptyState(
            ui: ui,
            icon: Icons.calendar_today_outlined,
            title: 'No Upcoming Bookings',
            subtitle: "You don't have any upcoming reservations",
            accentColor: ui.brandPrimary,
            iconOutlined: true,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: AppUtils.horizontal16Padding,
      itemCount: bookings.length,
      separatorBuilder: (_, __) => 14.verticalSpace,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return UpcomingBookingCard(
          ui: ui,
          booking: booking,
          isProcessing: state.isActionInProgress(booking.id),
          onModify: () => AppHelpers.showSnackBar(
            context,
            'Coming soon',
          ), //_openReschedule(context, cubit, booking),
          onCancel: () => _confirmCancel(context, cubit, booking),
          onScanQr: () => _scanBookingQrCode(context, booking),
        );
      },
    );
  }
}

Future<void> _confirmCancel(
  BuildContext context,
  MyBookingsCubit cubit,
  MyBookingEntity booking,
) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Cancel booking?'),
      content: Text(
        'Are you sure you want to cancel your booking at '
        '${booking.displayName} on ${booking.date} at ${booking.startTime}?',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep'),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Cancel booking'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final result = await cubit.cancelBooking(booking.id);
  if (!context.mounted) return;
  AppHelpers.showSnackBar(context, result.message, isError: !result.success);
}

Future<void> _openReschedule(
  BuildContext context,
  MyBookingsCubit cubit,
  MyBookingEntity booking,
) async {
  final selection = await RescheduleSheet.show(context, booking);
  if (selection == null || !context.mounted) return;

  final result = await cubit.rescheduleBooking(
    bookingId: booking.id,
    locationId: booking.locationId,
    bookingDate: selection.date,
    startTime: selection.startTime,
  );
  if (!context.mounted) return;
  AppHelpers.showSnackBar(context, result.message, isError: !result.success);
}

Future<void> _scanBookingQrCode(
  BuildContext context,
  MyBookingEntity booking,
) async {
  final result = await BarcodeScannerService.scanBookingQrCode(context);
  if (!context.mounted) return;

  switch (result) {
    case BookingQrScanSuccess(:final code):
      AppHelpers.showSnackBar(
        context,
        'QR scanned for ${booking.displayName}: $code',
      );
    case BookingQrScanPermissionDenied():
      AppHelpers.showSnackBar(
        context,
        'Camera permission is required to scan QR codes',
        isError: true,
      );
    case BookingQrScanFailure(:final message):
      AppHelpers.showSnackBar(context, message, isError: true);
    case BookingQrScanCancelled():
      break;
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({
    required this.ui,
    required this.state,
    required this.cubit,
  });

  final AppUiColors ui;
  final MyBookingsState state;
  final MyBookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    // First-ever load (or a load triggered with a spinner): show the loader.
    if (state.historyStatus == MyBookingsStatus.loading ||
        state.historyStatus == MyBookingsStatus.initial) {
      return Center(
        child: SizedBox(
          width: 28.w,
          height: 28.w,
          child: CircularProgressIndicator(
            strokeWidth: 2.6,
            color: ui.brandPrimary,
          ),
        ),
      );
    }

    if (state.historyStatus == MyBookingsStatus.failure) {
      return ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          60.verticalSpace,
          Icon(Icons.error_outline_rounded,
              color: ui.textSecondary, size: 40.sp),
          12.verticalSpace,
          AppText(
            state.historyError ?? 'Could not load your charging history.',
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          16.verticalSpace,
          Center(
            child: SizedBox(
              width: 160.w,
              child: PrimaryButtonWidget(
                text: 'Retry',
                onPress: cubit.loadHistory,
                buttonHeight: 40.h,
                cornerRadius: 22.r,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ),
        ],
      );
    }

    final sessions = state.historySessions;
    return RefreshIndicator(
      color: ui.brandPrimary,
      onRefresh: () => cubit.loadHistory(showSpinner: false),
      child: sessions.isEmpty
          ? ListView(
              padding: AppUtils.horizontal16Padding,
              children: [
                BookingEmptyState(
                  ui: ui,
                  icon: Icons.history_rounded,
                  title: 'No History',
                  subtitle: 'You have no charging sessions yet',
                  accentColor: ui.brandPrimary,
                  iconOutlined: true,
                ),
              ],
            )
          : ListView.separated(
              padding: AppUtils.horizontal16Padding,
              itemCount: sessions.length,
              separatorBuilder: (_, __) => 14.verticalSpace,
              itemBuilder: (context, index) => HistoryBookingCard(
                ui: ui,
                booking: _toHistory(sessions[index]),
              ),
            ),
    );
  }

  HistoryBooking _toHistory(ChargeSessionHistoryEntity s) {
    return HistoryBooking(
      stationName: s.displayName,
      dateTimeLabel: _formatStartedAt(s.startedAt),
      durationLabel: (s.duration != null && s.duration!.isNotEmpty)
          ? s.duration!
          : (s.isInProgress ? 'In progress' : '—'),
      statusLabel: s.status.isNotEmpty ? s.status : 'Unknown',
      isInProgress: s.isInProgress,
      energyKwh: s.energyConsumed,
      amount: s.totalCost,
    );
  }
}

/// Formats a `yyyy-MM-dd HH:mm:ss` timestamp into `MMM d, yyyy · h:mm a`,
/// falling back to the raw string (or a placeholder) when it can't be parsed.
String _formatStartedAt(String? raw) {
  if (raw == null || raw.isEmpty) return 'Date unavailable';
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;
  return DateFormat('MMM d, yyyy · h:mm a').format(parsed);
}

import 'dart:convert';

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
import 'package:orko_hubco/features/booking/presentation/widgets/active_session_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/booking_empty_state.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/bookings_tab_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/history_booking_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/reschedule_sheet.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/upcoming_booking_card.dart';
import 'package:orko_hubco/features/charging/presentation/page/charging_status_page.dart';

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
    // The Active and History tabs are driven by their own endpoints/state, so
    // they render independently of the my-bookings (Upcoming) load status.
    if (state.selectedTab == BookingTab.active) {
      return _ActiveTab(ui: ui, state: state, cubit: cubit);
    }
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
    final filter = state.upcomingFilter;
    final bookings = state.upcomingForFilter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: AppUtils.horizontal16Padding,
          child: _UpcomingFilterSelector(
            ui: ui,
            selected: filter,
            onSelected: cubit.selectUpcomingFilter,
          ),
        ),
        14.verticalSpace,
        Expanded(
          child: bookings.isEmpty
              ? ListView(
                  // Keep it scrollable so pull-to-refresh works when empty.
                  padding: AppUtils.horizontal16Padding,
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [
                    BookingEmptyState(
                      ui: ui,
                      icon: _emptyIcon(filter),
                      title: _emptyTitle(filter),
                      subtitle: _emptySubtitle(filter),
                      accentColor: ui.brandPrimary,
                      iconOutlined: true,
                    ),
                  ],
                )
              : ListView.separated(
                  padding: AppUtils.horizontal16Padding,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: bookings.length,
                  separatorBuilder: (_, __) => 14.verticalSpace,
                  itemBuilder: (context, index) {
                    final booking = bookings[index];
                    // Scan/Modify only apply to approved bookings. Pending ones
                    // can still be cancelled (gated by canCancel); cancelled
                    // ones are read-only.
                    final isApproved = booking.isApproved;
                    return UpcomingBookingCard(
                      ui: ui,
                      booking: booking,
                      isProcessing: state.isActionInProgress(booking.id),
                      showScanQr: isApproved,
                      showModify: isApproved,
                      onModify: () => _openReschedule(context, cubit, booking),
                      onCancel: () => _confirmCancel(context, cubit, booking),
                      onScanQr: () => _scanBookingQrCode(context, booking),
                    );
                  },
                ),
        ),
      ],
    );
  }

  IconData _emptyIcon(UpcomingFilter filter) {
    switch (filter) {
      case UpcomingFilter.approved:
        return Icons.calendar_today_outlined;
      case UpcomingFilter.cancelled:
        return Icons.event_busy_outlined;
    }
  }

  String _emptyTitle(UpcomingFilter filter) {
    switch (filter) {
      case UpcomingFilter.approved:
        return 'No Upcoming Bookings';
      case UpcomingFilter.cancelled:
        return 'No Cancelled Bookings';
    }
  }

  String _emptySubtitle(UpcomingFilter filter) {
    switch (filter) {
      case UpcomingFilter.approved:
        return "You don't have any upcoming reservations";
      case UpcomingFilter.cancelled:
        return "You don't have any cancelled bookings";
    }
  }
}

/// Pill segmented control switching the Approved/Cancelled sub-tabs.
class _UpcomingFilterSelector extends StatelessWidget {
  const _UpcomingFilterSelector({
    required this.ui,
    required this.selected,
    required this.onSelected,
  });

  final AppUiColors ui;
  final UpcomingFilter selected;
  final ValueChanged<UpcomingFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.r),
      decoration: BoxDecoration(
        color: ui.isLight
            ? AppColors.shimmerGreyColor
            : AppColors.whiteColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14.r),
      ),
      child: Row(
        children: UpcomingFilter.values.map((f) {
          final isSelected = f == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onSelected(f),
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOut,
                padding: EdgeInsets.symmetric(vertical: 9.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? ui.cardBackground
                      : AppColors.transparentColor,
                  borderRadius: BorderRadius.circular(10.r),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.blackColor.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: AppText(
                  f.label,
                  textAlign: TextAlign.center,
                  color: isSelected ? ui.textPrimary : ui.textSecondary,
                  fontSize: FontSizes.font13Sp,
                  fontWeight: isSelected
                      ? FontWeights.weight700
                      : FontWeights.weight500,
                ),
              ),
            ),
          );
        }).toList(),
      ),
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

/// Charger identity decoded from a scanned QR.
typedef _ChargerQr = ({String chargePointId, int connectorId});

Future<void> _scanBookingQrCode(
  BuildContext context,
  MyBookingEntity booking,
) async {
  // Capture the cubit before the scanner route is pushed.
  final cubit = context.read<MyBookingsCubit>();
  final result = await BarcodeScannerService.scanBookingQrCode(context);
  if (!context.mounted) return;

  switch (result) {
    case BookingQrScanSuccess(:final code):
      await _verifyScannedQr(context, cubit, booking, code);
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

/// Parses the scanned [code], calls `verify-qr`, and surfaces the outcome:
/// invalid QR, network/server failure, a match, or a wrong-connector mismatch.
Future<void> _verifyScannedQr(
  BuildContext context,
  MyBookingsCubit cubit,
  MyBookingEntity booking,
  String code,
) async {
  final parsed = _parseChargerQr(code);
  if (parsed == null) {
    AppHelpers.showSnackBar(
      context,
      "This QR code isn't a valid charger code. Please scan the code on the "
      'charger.',
      isError: true,
    );
    return;
  }
  if (booking.bookingCode.trim().isEmpty) {
    AppHelpers.showSnackBar(
      context,
      'This booking is missing its code and cannot be verified.',
      isError: true,
    );
    return;
  }

  // Block input while the request is in flight.
  showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const Center(child: CircularProgressIndicator()),
  );

  final either = await cubit.verifyQr(
    bookingCode: booking.bookingCode,
    chargePointId: parsed.chargePointId,
    connectorId: parsed.connectorId,
  );

  if (!context.mounted) return;
  // Dismiss the loader.
  Navigator.of(context, rootNavigator: true).pop();
  if (!context.mounted) return;

  either.fold(
    (failure) => AppHelpers.showSnackBar(context, failure.message, isError: true),
    (res) {
      if (res.isMatch) {
        _showVerifyResultDialog(
          context,
          title: 'Charger verified',
          message: 'This charger matches your booking'
              '${res.bookedConnectorId != null ? ' (connector ${res.bookedConnectorId}).' : '.'}'
              '\n\nYou\'re all set to start charging.',
          isError: false,
        );
      } else {
        final correct = res.message?.trim();
        final fallback = res.bookedConnectorId != null
            ? 'This charger doesn\'t match your booking. Your booking is for '
                'connector ${res.bookedConnectorId}.'
            : "This charger doesn't match your booking.";
        _showVerifyResultDialog(
          context,
          title: 'Wrong connector',
          message: '${(correct != null && correct.isNotEmpty) ? correct : fallback}'
              '\n\nThis mismatch has been reported to the operator.',
          isError: true,
        );
      }
    },
  );
}

void _showVerifyResultDialog(
  BuildContext context, {
  required String title,
  required String message,
  required bool isError,
}) {
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Row(
        children: [
          Icon(
            isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
            color: isError ? AppColors.removeColor : Colors.green.shade700,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Extracts the `charge_point_id` + `connector_id` a charger QR encodes.
///
/// Tolerant of the common encodings so a backend format change doesn't break
/// scanning: a JSON object, a URL/query string (`...?charge_point_id=CP1&
/// connector_id=2`), or a delimited pair (`CP00123:2`, `CP00123,2`, etc.).
/// Returns null when neither field can be recovered.
_ChargerQr? _parseChargerQr(String raw) {
  final code = raw.trim();
  if (code.isEmpty) return null;

  // 1) JSON object.
  try {
    final decoded = jsonDecode(code);
    if (decoded is Map) {
      final parsed = _normalizeChargerQr(
        decoded['charge_point_id'] ?? decoded['chargePointId'] ?? decoded['cp'],
        decoded['connector_id'] ?? decoded['connectorId'] ?? decoded['connector'],
      );
      if (parsed != null) return parsed;
    }
  } catch (_) {
    // Not JSON — fall through to the other formats.
  }

  // 2) URL / query string.
  final queryIndex = code.indexOf('?');
  final queryPart = queryIndex >= 0 ? code.substring(queryIndex + 1) : code;
  if (queryPart.contains('=')) {
    final params = <String, String>{};
    for (final pair in queryPart.split(RegExp(r'[&;]'))) {
      final kv = pair.split('=');
      if (kv.length == 2) {
        params[kv[0].trim().toLowerCase()] = kv[1].trim();
      }
    }
    final parsed = _normalizeChargerQr(
      params['charge_point_id'] ?? params['chargepointid'] ?? params['cp'],
      params['connector_id'] ??
          params['connectorid'] ??
          params['connector'] ??
          params['conn'],
    );
    if (parsed != null) return parsed;
  }

  // 3) Delimited pair, e.g. `CP00123:2`.
  final match = RegExp(r'^(.+?)[:,|/\-](\d+)$').firstMatch(code);
  if (match != null) {
    final parsed = _normalizeChargerQr(match.group(1), match.group(2));
    if (parsed != null) return parsed;
  }

  return null;
}

_ChargerQr? _normalizeChargerQr(dynamic chargePoint, dynamic connector) {
  final cp = chargePoint?.toString().trim();
  if (cp == null || cp.isEmpty) return null;
  final conn = connector is num
      ? connector.toInt()
      : int.tryParse(connector?.toString().trim() ?? '');
  if (conn == null) return null;
  return (chargePointId: cp, connectorId: conn);
}

/// Opens the full live charging-status screen, which polls the live-session
/// endpoint on its own. It builds its own cubit, so it's safe to push directly.
void _openLiveChargingSession(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute(builder: (_) => const ChargingStatusPage()),
  );
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({
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
    if (state.liveStatus == MyBookingsStatus.loading ||
        state.liveStatus == MyBookingsStatus.initial) {
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

    if (state.liveStatus == MyBookingsStatus.failure) {
      return ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          60.verticalSpace,
          Icon(Icons.error_outline_rounded,
              color: ui.textSecondary, size: 40.sp),
          12.verticalSpace,
          AppText(
            state.liveError ?? 'Could not load your active session.',
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
                onPress: cubit.loadLiveSession,
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

    final session = state.liveSession;
    final hasActiveSession = session != null && session.active;

    return RefreshIndicator(
      color: ui.brandPrimary,
      onRefresh: () => cubit.loadLiveSession(showSpinner: false),
      child: hasActiveSession
          ? ListView(
              padding: AppUtils.horizontal16Padding,
              children: [
                ActiveSessionCard(ui: ui, session: session),
                16.verticalSpace,
                PrimaryButtonWidget(
                  text: 'Live Charging Session',
                  onPress: () => _openLiveChargingSession(context),
                  buttonHeight: 40.h,
                  cornerRadius: 24.r,
                  gradientColors: const [
                    AppColors.primaryDarkColor,
                    AppColors.primaryDarkButtonColor,
                  ],
                  textColor: AppColors.whiteColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ],
            )
          : ListView(
              padding: AppUtils.horizontal16Padding,
              children: [
                BookingEmptyState(
                  ui: ui,
                  icon: Icons.bolt,
                  title: 'No Active Sessions',
                  subtitle: "You don't have any active charging sessions",
                  accentColor: ui.brandPrimary,
                  iconOutlined: true,
                ),
              ],
            ),
    );
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

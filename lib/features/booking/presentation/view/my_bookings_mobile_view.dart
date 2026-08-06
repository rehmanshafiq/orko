import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
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
import 'package:orko_hubco/features/booking/presentation/pages/session_summary_page.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/reschedule_sheet.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/upcoming_booking_card.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/view/charging_status_mobile_view.dart';

class MyBookingsMobileView extends StatefulWidget {
  const MyBookingsMobileView({super.key});

  @override
  State<MyBookingsMobileView> createState() => _MyBookingsMobileViewState();
}

class _MyBookingsMobileViewState extends State<MyBookingsMobileView>
    with WidgetsBindingObserver {
  /// Captured once so it's safe to use in [dispose], where the cubit can no
  /// longer be looked up via context.
  late final MyBookingsCubit _cubit;

  /// Whether this screen is the visible bottom-nav tab. This view lives inside
  /// the bottom-nav shell, where hidden tabs stay alive (so [dispose] is *not*
  /// called when the user switches to another bottom-nav tab). The shell drives
  /// [TickerMode] per visible tab, so we track it to stop the poll loop when
  /// this screen is off-screen and resume it when it's shown again.
  bool _isScreenVisible = true;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<MyBookingsCubit>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-invoked whenever TickerMode flips (i.e. this screen is shown/hidden by
    // the bottom-nav shell). Keep the poll loop in sync with visibility.
    _isScreenVisible = TickerMode.valuesOf(context).enabled;
    _syncLiveSessionPolling();
  }

  @override
  void dispose() {
    // Leaving the screen: stop the live-session poll loop so no further
    // requests fire once the view is gone (the cubit also stops it on close).
    _cubit.stopLiveSessionPolling();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pause the live-session poll when the app leaves the foreground; resume it
  /// on return, subject to the same visibility + tab gating as everywhere else.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (!mounted) return;
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        _syncLiveSessionPolling();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _cubit.stopLiveSessionPolling();
        break;
    }
  }

  /// Starts the live-session poll only while this screen is visible *and* the
  /// Live (Active) or Upcoming tab is selected; stops it otherwise. This is the
  /// single gate used by visibility, lifecycle, and tab changes.
  void _syncLiveSessionPolling() {
    if (!mounted) return;
    final tab = _cubit.state.selectedTab;
    final wantsPolling = _isScreenVisible &&
        (tab == BookingTab.active || tab == BookingTab.upcoming);
    if (wantsPolling) {
      _cubit.startLiveSessionPolling();
    } else {
      _cubit.stopLiveSessionPolling();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: BlocConsumer<MyBookingsCubit, MyBookingsState>(
          // A live session we were tracking has finished — show its summary.
          listenWhen: (previous, current) =>
              current.completedSessionId != null &&
              previous.completedSessionId != current.completedSessionId,
          listener: (context, state) =>
              _handleSessionCompleted(context, state.completedSessionId!),
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
                    'My Charging',
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
          title: 'No Live Sessions',
          subtitle: "You don't have any live charging sessions",
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
    // Only approved bookings live in the Upcoming tab now; cancelled and
    // no-show bookings moved to History.
    final bookings = state.upcomingApproved;

    if (bookings.isEmpty) {
      return ListView(
        // Keep it scrollable so pull-to-refresh works when empty.
        padding: AppUtils.horizontal16Padding,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          BookingEmptyState(
            ui: ui,
            icon: Icons.event_available_outlined,
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
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: bookings.length,
      separatorBuilder: (_, __) => 14.verticalSpace,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        // All rows here are approved, so Scan/Modify always apply.
        return UpcomingBookingCard(
          ui: ui,
          booking: booking,
          isProcessing: state.isActionInProgress(booking.id),
          showScanQr: true,
          showModify: true,
          onModify: () => _openReschedule(context, cubit, booking),
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
        '${booking.displayName} on ${booking.displayDate} at ${booking.startTime}?',
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
  if (result.success) {
    sl<AnalyticsService>().logEvent('booking_cancelled', parameters: {
      'booking_id': booking.id,
      'hours_before': _hoursUntilBookingStart(booking),
    });
  }
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

  // Captured before the reschedule so `hours_before` reflects how far ahead the
  // *original* slot was when the user changed it.
  final hoursBefore = _hoursUntilBookingStart(booking);
  final result = await cubit.rescheduleBooking(
    bookingId: booking.id,
    locationId: booking.locationId,
    bookingDate: selection.date,
    startTime: selection.startTime,
    noOfSlots: selection.noOfSlots,
  );
  if (result.success) {
    sl<AnalyticsService>().logEvent('booking_rescheduled', parameters: {
      'booking_id': booking.id,
      'hours_before': hoursBefore,
    });
  }
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

/// Shows the post-session summary for [sessionId], then hands off from Active
/// to History — where the just-finished session now shows up — if that's
/// where the user was watching it. Otherwise just refreshes the Active tab so
/// the ended session disappears from it.
///
/// The one-shot flag is consumed first so a later live-session load can
/// re-trigger this if the summary couldn't be shown right now (this screen
/// lives inside the bottom-nav shell, where hidden tabs stay alive — TickerMode
/// is false for them, and we skip pushing a screen over an invisible tab).
Future<void> _handleSessionCompleted(
  BuildContext context,
  int sessionId,
) async {
  final cubit = context.read<MyBookingsCubit>();
  cubit.consumeSessionCompletion();
  if (!TickerMode.valuesOf(context).enabled) return;

  await SessionSummaryPage.show(context, sessionId: sessionId);
  if (cubit.state.selectedTab == BookingTab.active) {
    cubit.selectTab(BookingTab.history);
  } else {
    cubit.loadLiveSession(showSpinner: false);
  }
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

    // A session is running: show the live charging-status content inline
    // (gauge, metrics, station info — same as the charging status screen,
    // with a LIVE badge top-right). It gets its own cubit, which polls the
    // live-session endpoint on its own; when the session ends we refresh the
    // bookings copy so this tab flips back to the empty state.
    if (hasActiveSession) {
      return BlocProvider(
        create: (_) => sl<ChargingStatusCubit>()..start(),
        child: ChargingStatusMobileView(
          embedded: true,
          // The summary is already shown by this point; hand off to History,
          // where the just-finished session now shows up.
          onSessionEnded: () => cubit.selectTab(BookingTab.history),
        ),
      );
    }

    return RefreshIndicator(
      color: ui.brandPrimary,
      onRefresh: () => cubit.loadLiveSession(showSpinner: false),
      child: ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          BookingEmptyState(
            ui: ui,
            icon: Icons.bolt,
            title: 'No Live Sessions',
            subtitle: "You don't have any live charging sessions",
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

    // History = actual charging sessions plus the bookings that never
    // happened (cancelled / no-show), which moved here from the Upcoming tab.
    // Everything is merged by date (newest first) and capped at the 15 most
    // recent entries.
    final entries = <_DatedHistoryItem>[
      for (final s in state.historySessions)
        _DatedHistoryItem(
          date: _parseDateTime(s.startedAt),
          item: _HistoryItem(
            booking: _sessionToHistory(s),
            // Only real sessions have a summary to open.
            onTap: () => SessionSummaryPage.show(
              context,
              sessionId: s.id,
              showPaymentButtons: false,
            ),
          ),
        ),
      for (final b in state.upcomingCancelled)
        _DatedHistoryItem(
          date: _parseDateTime('${b.date} ${b.startTime}') ??
              _parseDateTime(b.date),
          item: _HistoryItem(booking: _bookingToHistory(b)),
        ),
    ];
    // Newest first; entries whose date can't be parsed sink to the bottom.
    entries.sort((a, b) {
      if (a.date == null && b.date == null) return 0;
      if (a.date == null) return 1;
      if (b.date == null) return -1;
      return b.date!.compareTo(a.date!);
    });
    final items = entries
        .take(_maxHistoryItems)
        .map((e) => e.item)
        .toList(growable: false);

    return RefreshIndicator(
      color: ui.brandPrimary,
      onRefresh: () => cubit.loadHistory(showSpinner: false),
      child: items.isEmpty
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
              itemCount: items.length,
              separatorBuilder: (_, __) => 14.verticalSpace,
              itemBuilder: (context, index) {
                final item = items[index];
                return HistoryBookingCard(
                  ui: ui,
                  booking: item.booking,
                  onTap: item.onTap,
                );
              },
            ),
    );
  }

  HistoryBooking _sessionToHistory(ChargeSessionHistoryEntity s) {
    return HistoryBooking(
      stationName: s.displayName,
      dateTimeLabel: _formatStartedAt(s.startedAt),
      durationLabel: (s.duration != null && s.duration!.isNotEmpty)
          ? s.duration!
          : (s.isInProgress ? 'In progress' : '—'),
      statusLabel: s.status.isNotEmpty ? s.status : 'Unknown',
      isInProgress: s.isInProgress,
      isWalkIn: s.isWalkIn,
      energyKwh: s.energyConsumed,
      amount: s.totalCost,
    );
  }

  /// Renders a cancelled / no-show booking as a History row. Shows the booked
  /// date and start time (24-hour), matching the completed-session rows.
  HistoryBooking _bookingToHistory(MyBookingEntity b) {
    return HistoryBooking(
      stationName: b.displayName,
      dateTimeLabel: [b.displayDate, _formatTime24(b.startTime)]
          .where((p) => p.isNotEmpty)
          .join(' · '),
      durationLabel: '—',
      statusLabel: b.isNoShow ? 'No Show' : 'Cancelled',
      isInProgress: false,
      isCancelled: b.isCancelled,
      isNoShow: b.isNoShow,
      energyKwh: null,
      // No charging happened, so there's no real cost to show.
      amount: null,
    );
  }
}

/// The History tab shows at most this many rows (sessions + cancelled
/// bookings combined), newest first.
const int _maxHistoryItems = 15;

/// A single History-tab row: the card model plus an optional tap handler
/// (real sessions open their summary; cancelled/no-show bookings don't).
class _HistoryItem {
  const _HistoryItem({required this.booking, this.onTap});

  final HistoryBooking booking;
  final VoidCallback? onTap;
}

/// A History row paired with the timestamp used to sort and cap the list.
class _DatedHistoryItem {
  const _DatedHistoryItem({required this.date, required this.item});

  final DateTime? date;
  final _HistoryItem item;
}

/// Hours between now and the booking's scheduled start, rounded to one decimal
/// (e.g. `2.5`). Null when the date/time can't be parsed; negative when the
/// start is already in the past. Used as `hours_before` on the
/// `booking_cancelled` / `booking_rescheduled` analytics events.
double? _hoursUntilBookingStart(MyBookingEntity booking) {
  final start = _parseDateTime('${booking.date} ${booking.startTime}') ??
      _parseDateTime(booking.date);
  if (start == null) return null;
  final hours = start.difference(DateTime.now()).inMinutes / 60.0;
  return (hours * 10).round() / 10;
}

/// Parses `yyyy-MM-dd HH:mm[:ss]`-style timestamps; null when unparseable so
/// the row sorts to the bottom instead of taking a bogus position.
DateTime? _parseDateTime(String? raw) {
  final trimmed = raw?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return DateTime.tryParse(trimmed.replaceFirst(' ', 'T'));
}

/// Formats a `yyyy-MM-dd HH:mm:ss` timestamp into `dd/MM/yyyy · HH:mm`
/// (24-hour), falling back to the raw string (or a placeholder) when it can't
/// be parsed.
String _formatStartedAt(String? raw) {
  if (raw == null || raw.isEmpty) return 'Date unavailable';
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;
  return DateFormat('dd/MM/yyyy · HH:mm').format(parsed);
}

/// Normalizes a raw time string (`HH:mm[:ss]` or `h:mm a`) to 24-hour `HH:mm`,
/// falling back to the trimmed input when it can't be parsed.
String _formatTime24(String? raw) {
  final trimmed = raw?.trim() ?? '';
  if (trimmed.isEmpty) return '';
  for (final pattern in ['HH:mm:ss', 'HH:mm', 'h:mm a', 'h:mm:ss a']) {
    try {
      return DateFormat('HH:mm').format(DateFormat(pattern).parseLoose(trimmed));
    } catch (_) {
      // Try the next pattern.
    }
  }
  return trimmed;
}

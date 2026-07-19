import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/pages/session_summary_page.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/live_badge.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/walkin_badge.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_gauge_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_meta_item_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/metrics_grid_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/station_info_widget.dart';

class ChargingStatusMobileView extends StatefulWidget {
  const ChargingStatusMobileView({
    super.key,
    this.embedded = false,
    this.onSessionEnded,
  });

  /// True when this view is inlined inside another screen (the My Bookings
  /// Active tab) rather than pushed as its own route: the Scaffold/SafeArea
  /// and back arrow are dropped, and a LIVE badge is shown top-right instead.
  final bool embedded;

  /// Embedded mode only: called after the post-session summary is dismissed,
  /// so the host screen can refresh its own live-session state.
  final VoidCallback? onSessionEnded;

  @override
  State<ChargingStatusMobileView> createState() =>
      _ChargingStatusMobileViewState();
}

class _ChargingStatusMobileViewState extends State<ChargingStatusMobileView>
    with WidgetsBindingObserver {
  /// Captured once so it's safe to use in [dispose], where looking the cubit up
  /// via context is no longer reliable.
  late final ChargingStatusCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<ChargingStatusCubit>();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    // Navigating back tears down this view: stop the live-session polling
    // immediately so no further requests fire after we leave the screen. The
    // BlocProvider also closes the cubit on pop, but pausing here guarantees
    // the timer is cancelled the moment the view is gone.
    _cubit.pause();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Pause polling when the app leaves the foreground; resume on return. This
  /// keeps the 10s timer from firing network calls the user can't see.
  @override
  void didChangeAppLifecycleState(AppLifecycleState lifecycleState) {
    if (!mounted) return;
    switch (lifecycleState) {
      case AppLifecycleState.resumed:
        _cubit.resume();
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.hidden:
      case AppLifecycleState.detached:
        _cubit.pause();
        break;
    }
  }

  /// Shows the post-session summary once the session we were watching ends,
  /// then pops this (now stale) screen when it was pushed from My Bookings.
  ///
  /// The one-shot flag is consumed first so the next 10s poll re-triggers this
  /// if the summary couldn't be shown right now — this screen also lives as a
  /// hidden-but-alive bottom-nav tab, where TickerMode is false and pushing a
  /// screen over an invisible tab would be wrong.
  Future<void> _handleSessionCompleted(int sessionId) async {
    _cubit.consumeSessionCompletion();
    if (!mounted || !TickerMode.valuesOf(context).enabled) return;

    await SessionSummaryPage.show(context, sessionId: sessionId);
    if (!mounted) return;
    // Embedded in the My Bookings Active tab: stay put and let the host
    // refresh its live-session state (which swaps in its empty state).
    if (widget.embedded) {
      widget.onSessionEnded?.call();
      return;
    }
    // Pushed from My Bookings: return there (the session is over, so this
    // screen has nothing live to show). As a bottom-nav tab root this is a
    // no-op and the screen simply shows its idle state.
    Navigator.of(context).maybePop();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final content = Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: ui.isLight
                  ? [
                      AppColors.scaffoldColor,
                      AppColors.shimmerGreyColor,
                    ]
                  : [
                      AppColors.darkScaffoldBackgroundColor,
                      AppColors.darkScaffoldBackgroundColor,
                    ],
            ),
          ),
          child: BlocConsumer<ChargingStatusCubit, ChargingStatusState>(
            // The live session we were watching has finished — show its summary.
            listenWhen: (previous, current) =>
                current.completedSessionId != null &&
                previous.completedSessionId != current.completedSessionId,
            listener: (context, state) =>
                _handleSessionCompleted(state.completedSessionId!),
            builder: (context, state) {
              final cubit = context.read<ChargingStatusCubit>();
              return ListView(
                padding: AppUtils.horizontal16Padding,
                children: [
                  8.verticalSpace,
                  Row(
                    children: [
                      // Embedded in the Active tab there's no back to go to and
                      // no headline — the LIVE badge is pinned top-right, with
                      // the Walk-in badge (when applicable) top-left.
                      if (widget.embedded) ...[
                        if (state.isWalkinSession) const WalkinBadge(),
                        const Spacer(),
                        const LiveBadge(),
                      ] else ...[
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => Navigator.maybePop(context),
                          child: Padding(
                            padding: EdgeInsets.all(6.r),
                            child: Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: ui.textMuted,
                              size: 20.sp,
                            ),
                          ),
                        ),
                        // Walk-in sessions get a badge just after the back arrow
                        // (top-left) so they're distinguishable from booked ones.
                        if (state.isWalkinSession) ...[
                          6.horizontalSpace,
                          const WalkinBadge(),
                        ],
                        Expanded(
                          child: AppText(
                            state.stationHeadline,
                            textAlign: TextAlign.center,
                            color: ui.textMuted,
                            fontSize: FontSizes.font16Sp,
                            fontWeight: FontWeights.weight400,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Balances the back icon so the headline stays centered.
                        SizedBox(width: 20.sp + 12.r),
                      ],
                    ],
                  ),
                  26.verticalSpace,
                  ChargingGaugeWidget(
                    progress: state.gaugeProgress,
                    percentLabel: state.gaugePercentLabel,
                    statusLabel: state.statusLabel,
                    ui: ui,
                  ),
                  36.verticalSpace,
                  MetricsGridWidget(metrics: state.metrics, ui: ui),
                  // No backing booking (e.g. walk-in sessions) → no booked-slot
                  // card to show.
                  if (state.hasBooking) ...[
                    12.verticalSpace,
                    _ChargingSessionTargetCard(
                      ui: ui,
                      estimatedTimeLabel: state.estimatedTimeLabel,
                      bookingTimeLeftLabel: state.bookingTimeLeftLabel,
                      sliderValue: state.sliderValue,
                      targetPercentLabel: state.targetPercentLabel,
                      onSliderChanged: cubit.updateProgress,
                    ),
                  ],
                  12.verticalSpace,
                  // StationInfoWidget(
                  //   infoText: state.stationInfoText,
                  //   ui: ui,
                  //   operatingHours: state.operatingHoursText,
                  //   pricing: state.priceText,
                  //   contact: state.contactText,
                  // ),
                  // if (state.distanceKm > 0) ...[
                  //   8.verticalSpace,
                  //   Align(
                  //     alignment: Alignment.centerLeft,
                  //     child: ChargingStationMetaItemWidget(
                  //       icon: Icons.location_on_rounded,
                  //       text: AppHelpers.formatDistanceKm(state.distanceKm),
                  //       iconColor: AppColors.mapPinBlueColor,
                  //       textColor: AppColors.mapPinBlueColor,
                  //       textFontWeight: FontWeights.weight600,
                  //     ),
                  //   ),
                  // ],
                  // 10.verticalSpace,
                  // ChargingActionButtonsWidget(
                  //   onStopCharging: cubit.stopCharging,
                  //   onEmergencyStop: cubit.emergencyStop,
                  // ),
                  // 8.verticalSpace,
                ],
              );
            },
          ),
        );

    // Embedded in the My Bookings Active tab — the host owns the
    // Scaffold/SafeArea.
    if (widget.embedded) return content;

    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(child: content),
    );
  }
}

class _ChargingSessionTargetCard extends StatelessWidget {
  const _ChargingSessionTargetCard({
    required this.ui,
    required this.estimatedTimeLabel,
    required this.bookingTimeLeftLabel,
    required this.sliderValue,
    required this.targetPercentLabel,
    required this.onSliderChanged,
  });

  final AppUiColors ui;
  final String estimatedTimeLabel;

  /// Live `HH:MM:SS` countdown of the booked slot; empty hides the row.
  final String bookingTimeLeftLabel;
  final double sliderValue;
  final String targetPercentLabel;
  final ValueChanged<double> onSliderChanged;

  @override
  Widget build(BuildContext context) {
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 6.h,
      activeTrackColor: ui.brandPrimary,
      inactiveTrackColor: ui.progressTrack,
      thumbColor: ui.brandPrimary,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 9.r),
      overlayShape: SliderComponentShape.noOverlay,
    );
    return Container(
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.searchBackground.withValues(alpha: ui.isLight ? 1 : null),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        children: [
          // AppText(
          //   estimatedTimeLabel,
          //   color: ui.brandPrimary,
          //   fontSize: FontSizes.font18Sp,
          //   fontWeight: FontWeights.weight600,
          // ),
          if (bookingTimeLeftLabel.isNotEmpty) ...[
            // 4.verticalSpace,
            AppText(
              'Remaining Booked Slot Time',
              color: ui.textMuted,
              fontSize: FontSizes.font15Sp,
              fontWeight: FontWeights.weight500,
            ),
            4.verticalSpace,
            AppText(
              bookingTimeLeftLabel,
              color: ui.brandPrimary,
              fontSize: FontSizes.font18Sp,
              fontWeight: FontWeights.weight600,
            ),
          ],
          // 8.verticalSpace,
          // AppText(
          //   targetPercentLabel,
          //   color: ui.textSecondaryWhite,
          //   fontSize: FontSizes.font13Sp,
          //   fontWeight: FontWeights.weight500,
          // ),
          // 8.verticalSpace,
          // SliderTheme(
          //   data: sliderTheme,
          //   child: Slider(
          //     value: sliderValue,
          //     onChanged: onSliderChanged,
          //   ),
          // ),
        ],
      ),
    );
  }
}

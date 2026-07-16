import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_gauge_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_meta_item_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/metrics_grid_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/station_info_widget.dart';

class ChargingStatusMobileView extends StatefulWidget {
  const ChargingStatusMobileView({super.key});

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

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: Container(
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
          child: BlocBuilder<ChargingStatusCubit, ChargingStatusState>(
            builder: (context, state) {
              final cubit = context.read<ChargingStatusCubit>();
              return ListView(
                padding: AppUtils.horizontal16Padding,
                children: [
                  8.verticalSpace,
                  Row(
                    children: [
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
                  12.verticalSpace,
                  _ChargingSessionTargetCard(
                    ui: ui,
                    estimatedTimeLabel: state.estimatedTimeLabel,
                    bookingTimeLeftLabel: state.bookingTimeLeftLabel,
                    sliderValue: state.sliderValue,
                    targetPercentLabel: state.targetPercentLabel,
                    onSliderChanged: cubit.updateProgress,
                  ),
                  12.verticalSpace,
                  StationInfoWidget(
                    infoText: state.stationInfoText,
                    ui: ui,
                    operatingHours: state.operatingHoursText,
                    pricing: state.priceText,
                    contact: state.contactText,
                  ),
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
                  10.verticalSpace,
                  // ChargingActionButtonsWidget(
                  //   onStopCharging: cubit.stopCharging,
                  //   onEmergencyStop: cubit.emergencyStop,
                  // ),
                  // 8.verticalSpace,
                ],
              );
            },
          ),
        ),
      ),
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
          AppText(
            estimatedTimeLabel,
            color: ui.brandPrimary,
            fontSize: FontSizes.font18Sp,
            fontWeight: FontWeights.weight600,
          ),
          if (bookingTimeLeftLabel.isNotEmpty) ...[
            8.verticalSpace,
            AppText(
              'Booked Slot Time Left',
              color: ui.textMuted,
              fontSize: FontSizes.font13Sp,
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
          8.verticalSpace,
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

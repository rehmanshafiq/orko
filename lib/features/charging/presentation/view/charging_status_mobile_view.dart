import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_action_buttons_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_gauge_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/metrics_grid_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/station_info_widget.dart';

class ChargingStatusMobileView extends StatelessWidget {
  const ChargingStatusMobileView({super.key});

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
                      const Color(0xFF0A1220),
                      AppColors.blackColor,
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
                  AppText(
                    state.stationHeadline,
                    textAlign: TextAlign.center,
                    color: ui.textMuted,
                    fontSize: FontSizes.font12Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                  38.verticalSpace,
                  ChargingGaugeWidget(
                    progress: state.gaugeProgress,
                    percentLabel: state.gaugePercentLabel,
                    statusLabel: state.statusLabel,
                    ui: ui,
                  ),
                  16.verticalSpace,
                  MetricsGridWidget(metrics: state.metrics, ui: ui),
                  16.verticalSpace,
                  _ChargingSessionTargetCard(
                    ui: ui,
                    estimatedTimeLabel: state.estimatedTimeLabel,
                    sliderValue: state.sliderValue,
                    targetPercentLabel: state.targetPercentLabel,
                    onSliderChanged: cubit.updateProgress,
                  ),
                  12.verticalSpace,
                  StationInfoWidget(
                    infoText: state.stationInfoText,
                    ui: ui,
                  ),
                  10.verticalSpace,
                  ChargingActionButtonsWidget(
                    onStopCharging: cubit.stopCharging,
                    onEmergencyStop: cubit.emergencyStop,
                  ),
                  8.verticalSpace,
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
    required this.sliderValue,
    required this.targetPercentLabel,
    required this.onSliderChanged,
  });

  final AppUiColors ui;
  final String estimatedTimeLabel;
  final double sliderValue;
  final String targetPercentLabel;
  final ValueChanged<double> onSliderChanged;

  @override
  Widget build(BuildContext context) {
    final sliderTheme = SliderTheme.of(context).copyWith(
      trackHeight: 3.h,
      activeTrackColor: AppColors.primaryDarkColor,
      inactiveTrackColor: ui.progressTrack,
      thumbColor: AppColors.primaryLightColor,
      thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
      overlayShape: SliderComponentShape.noOverlay,
    );
    return Container(
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground.withValues(alpha: ui.isLight ? 1 : 0.65),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        children: [
          AppText(
            estimatedTimeLabel,
            color: AppColors.primaryLightColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight600,
          ),
          10.verticalSpace,
          SliderTheme(
            data: sliderTheme,
            child: Slider(
              value: sliderValue,
              onChanged: onSliderChanged,
            ),
          ),
          AppText(
            targetPercentLabel,
            color: ui.textSecondary,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }
}

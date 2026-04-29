import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class ChargingStatusScreen extends StatelessWidget {
  const ChargingStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFF0A1220),
                AppColors.blackColor,
              ],
            ),
          ),
          child: ListView(
            padding: AppUtils.horizontal16Padding,
            children: [
              8.verticalSpace,
              AppText(
                'HGL Charging Hub M2 Port 2 CCS',
                textAlign: TextAlign.center,
                color: AppColors.whiteColor.withValues(alpha: 0.55),
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
              ),
              18.verticalSpace,
              _chargingGauge(),
              16.verticalSpace,
              _metricsGrid(),
              14.verticalSpace,
              Container(
                padding: AppUtils.all12Padding,
                decoration: BoxDecoration(
                  color: AppColors.fieldBackgroundColor.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    AppText(
                      'Est. Full Charge in 16 min',
                      color: AppColors.primaryLightColor,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                    10.verticalSpace,
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3.h,
                        activeTrackColor: AppColors.primaryDarkColor,
                        inactiveTrackColor: AppColors.whiteColor.withValues(alpha: 0.2),
                        thumbColor: AppColors.primaryLightColor,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6.r),
                        overlayShape: SliderComponentShape.noOverlay,
                      ),
                      child: Slider(
                        value: 0.80,
                        onChanged: (_) {},
                      ),
                    ),
                    AppText(
                      '80% Target',
                      color: AppColors.whiteColor.withValues(alpha: 0.7),
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight500,
                    ),
                  ],
                ),
              ),
              12.verticalSpace,
              Container(
                padding: AppUtils.vertical10Horizontal12Padding,
                decoration: BoxDecoration(
                  color: AppColors.fieldBackgroundColor.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'Station Info - HGL Charging Hub M2',
                        color: AppColors.whiteColor.withValues(alpha: 0.75),
                        fontSize: FontSizes.font10Sp,
                        fontWeight: FontWeights.weight400,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    8.horizontalSpace,
                    Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.whiteColor.withValues(alpha: 0.7)),
                  ],
                ),
              ),
              10.verticalSpace,
              PrimaryButtonWidget(
                text: 'Stop Charging',
                onPress: () {},
                buttonColor: AppColors.transparentColor,
                strokeColor: AppColors.removeColor,
                textColor: AppColors.removeColor,
                fontWeight: FontWeights.weight600,
                cornerRadius: 22.r,
              ),
              10.verticalSpace,
              Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6E1118), Color(0xFFA31C25)],
                  ),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: PrimaryButtonWidget(
                  text: 'Emergency Stop',
                  onPress: () {},
                  buttonColor: AppColors.transparentColor,
                  textColor: AppColors.whiteColor,
                  fontWeight: FontWeights.weight700,
                  cornerRadius: 12.r,
                ),
              ),
              8.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }

  Widget _chargingGauge() {
    return Container(
      padding: AppUtils.vertical8Padding,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer thick glow ring (matches design halo).
          CircularPercentIndicator(
            radius: 92.w,
            lineWidth: 14.w,
            percent: 0.67,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: AppColors.primaryLightColor.withValues(alpha: 0.70),
            backgroundColor: AppColors.primaryDarkColor.withValues(alpha: 0.12),
            backgroundWidth: 14.w,
            startAngle: 0,
            maskFilter: const MaskFilter.blur(BlurStyle.normal, 7),
            animation: false,
            center: const SizedBox.shrink(),
          ),

          // Inner crisp ring (matches design arc thickness).
          CircularPercentIndicator(
            radius: 86.w,
            lineWidth: 10.w,
            backgroundWidth: 10.w,
            percent: 0.67,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: AppColors.primaryLightColor,
            backgroundColor: AppColors.primaryDarkColor.withValues(alpha: 0.18),
            startAngle: 0,
            maskFilter: const MaskFilter.blur(BlurStyle.normal, 2.2),
            animation: false,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText(
                  '67%',
                  color: AppColors.whiteColor,
                  fontSize: FontSizes.font34Sp,
                  fontWeight: FontWeight.bold,
                ),
                AppText(
                  'Charging',
                  color: AppColors.whiteColor.withValues(alpha: 0.8),
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
                8.verticalSpace,
                Icon(
                  Icons.bolt_rounded,
                  color: AppColors.primaryLightColor,
                  size: 32.sp,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Energy Delivered', '8.4', 'kWh', Icons.battery_4_bar_rounded)),
            8.horizontalSpace,
            Expanded(child: _metricCard('Charging Speed', '150', 'kW', Icons.bolt_rounded)),
          ],
        ),
        8.verticalSpace,
        Row(
          children: [
            Expanded(child: _metricCard('Session Time', '00:33:42', '', Icons.access_time_rounded)),
            8.horizontalSpace,
            Expanded(child: _metricCard('Current Cost', 'Rs 378', '', Icons.payments_outlined)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String label, String value, String unit, IconData icon) {
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 24.w,
            height: 24.w,
            padding: AppUtils.all4Padding,
            decoration: BoxDecoration(
              color: AppColors.whiteColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(5.r),
              border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.10), width: 1),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 14.sp,
                color: AppColors.whiteColor.withValues(alpha: 0.70),
              ),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  color: AppColors.whiteColor.withValues(alpha: 0.55),
                  fontSize: FontSizes.font10Sp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                2.verticalSpace,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      value,
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font16Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    if (unit.isNotEmpty) ...[
                      4.horizontalSpace,
                      AppText(
                        unit,
                        color: AppColors.whiteColor.withValues(alpha: 0.85),
                        fontSize: FontSizes.font12Sp,
                        fontWeight: FontWeights.weight600,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

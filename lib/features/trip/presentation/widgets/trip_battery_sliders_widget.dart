import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripBatterySlidersWidget extends StatelessWidget {
  const TripBatterySlidersWidget({
    required this.currentBatteryPercent,
    required this.targetArrivalBatteryPercent,
    required this.kmPerPercentCharge,
    required this.onCurrentBatteryChanged,
    required this.onTargetArrivalBatteryChanged,
    super.key,
  });

  final double currentBatteryPercent;
  final double targetArrivalBatteryPercent;
  final double kmPerPercentCharge;
  final ValueChanged<double> onCurrentBatteryChanged;
  final ValueChanged<double> onTargetArrivalBatteryChanged;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final usableRangeKm = (currentBatteryPercent * kmPerPercentCharge).round();

    return Container(
      padding: AppUtils.horizontal8Vertical8Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Current Battery',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                ),
              ),
              8.horizontalSpace,
              AppText(
                '${currentBatteryPercent.round()}%',
                color: AppColors.primaryDarkColor,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
          6.verticalSpace,
          _batterySliderTheme(
            context,
            child: Slider(
              value: currentBatteryPercent.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onCurrentBatteryChanged,
            ),
          ),
          4.verticalSpace,
          AppText(
            '≈ $usableRangeKm km usable range (100% = 380 km)',
            color: ui.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
          ),
          18.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Target Arrival Battery',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                ),
              ),
              8.horizontalSpace,
              AppText(
                '${targetArrivalBatteryPercent.round()}%',
                color: AppColors.primaryDarkColor,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
          6.verticalSpace,
          _batterySliderTheme(
            context,
            child: Slider(
              value: targetArrivalBatteryPercent.clamp(0, 100),
              min: 0,
              max: 100,
              divisions: 100,
              onChanged: onTargetArrivalBatteryChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _batterySliderTheme(BuildContext context, {required Widget child}) {
    final ui = AppUiColors.of(context);
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4.h,
        activeTrackColor: AppColors.primaryDarkColor,
        inactiveTrackColor: ui.progressTrack,
        thumbColor: AppColors.primaryDarkColor,
        thumbShape: RoundSliderThumbShape(
          enabledThumbRadius: 10.r,
          elevation: 0,
          pressedElevation: 0,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: 18.r),
        overlayColor: WidgetStateColor.resolveWith(
          (_) => AppColors.primaryDarkColor.withValues(alpha: 0.16),
        ),
      ),
      child: child,
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// "Current Battery" slider: bold title with the live percentage on the right.
class TripCurrentBatterySliderWidget extends StatelessWidget {
  const TripCurrentBatterySliderWidget({
    required this.currentBatteryPercent,
    required this.onChanged,
    super.key,
  });

  final double currentBatteryPercent;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: AppText(
                'Current Battery',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
            8.horizontalSpace,
            AppText(
              '${currentBatteryPercent.round()}%',
              color: ui.brandPrimary,
              fontSize: FontSizes.font16Sp,
              fontWeight: FontWeights.weight700,
            ),
          ],
        ),
        6.verticalSpace,
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 4.h,
            activeTrackColor: ui.brandPrimary,
            inactiveTrackColor: ui.progressTrack,
            thumbShape: RoundSliderThumbShape(
              enabledThumbRadius: 6.r,
              elevation: 0,
              pressedElevation: 0,
            ),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 12.r),
            thumbColor: ui.brandPrimary,
          ),
          child: Slider(
            value: currentBatteryPercent.clamp(0, 100),
            min: 0,
            max: 100,
            onChanged: (v) => onChanged(v.roundToDouble()),
          ),
        ),
      ],
    );
  }
}

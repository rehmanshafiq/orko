import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class ChargingGaugeWidget extends StatelessWidget {
  const ChargingGaugeWidget({
    super.key,
    required this.progress,
    required this.percentLabel,
    required this.statusLabel,
    required this.ui,
  });

  final double progress;
  final String percentLabel;
  final String statusLabel;
  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Container(
      padding: AppUtils.vertical8Padding,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer thick glow ring (matches design halo).
          CircularPercentIndicator(
            radius: 92.w,
            lineWidth: 14.w,
            percent: p,
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
            percent: p,
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
                  percentLabel,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font34Sp,
                  fontWeight: FontWeight.bold,
                ),
                AppText(
                  statusLabel,
                  color: ui.textSecondary,
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
}

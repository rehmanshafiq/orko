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

  /// Whether the label ends in a `%` sign (rendered smaller, separately).
  bool get _hasPercentSign => percentLabel.trimRight().endsWith('%');

  /// The numeric part of [percentLabel] without a trailing `%`.
  String get _percentNumber => _hasPercentSign
      ? percentLabel.trimRight().substring(0, percentLabel.trimRight().length - 1)
      : percentLabel;

  @override
  Widget build(BuildContext context) {
    final p = progress.clamp(0.0, 1.0);
    return Container(
      padding: AppUtils.vertical8Padding,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer thick glow ring (matches design halo).
          // CircularPercentIndicator(
          //   radius: 92.w,
          //   lineWidth: 14.w,
          //   percent: p,
          //   circularStrokeCap: CircularStrokeCap.round,
          //   progressColor: AppColors.primaryLightColor.withValues(alpha: 0.70),
          //   backgroundColor: AppColors.primaryDarkColor.withValues(alpha: 0.12),
          //   backgroundWidth: 14.w,
          //   startAngle: 0,
          //   maskFilter: const MaskFilter.blur(BlurStyle.normal, 7),
          //   animation: false,
          //   center: const SizedBox.shrink(),
          // ),

          // Inner crisp ring (matches design arc thickness).
          CircularPercentIndicator(
            radius: 104.w,
            lineWidth: 8.w,
            percent: p,
            circularStrokeCap: CircularStrokeCap.round,
            progressColor: ui.brandPrimary,
            backgroundColor: ui.progressTrack,
            startAngle: 0,
            animation: false,
            center: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    10.horizontalSpace,
                    AppText(
                      _percentNumber,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font46Sp,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                    2.horizontalSpace,
                    if (_hasPercentSign)
                      Padding(
                        padding: EdgeInsets.only(bottom: 6.h),
                        child: AppText(
                          '%',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font22Sp,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                      ),
                  ],
                ),
                4.verticalSpace,
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      color: ui.textMuted,
                      size: 24.sp,
                    ),
                    // 4.horizontalSpace,
                    AppText(
                      statusLabel,
                      color: ui.textSecondary,
                      fontSize: FontSizes.font20Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                    6.horizontalSpace,
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

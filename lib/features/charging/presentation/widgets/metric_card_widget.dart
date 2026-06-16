import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class MetricCardWidget extends StatelessWidget {
  const MetricCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
    required this.ui,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;
  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUtils.horizontal8Vertical8Padding,
      decoration: BoxDecoration(
        color: ui.searchBackground.withValues(alpha: ui.isLight ? 1 : null),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            height: 30.w,
            child: Center(
              child: Icon(
                icon,
                size: 19.sp,
                color: ui.isLight ? ui.brandPrimary : AppColors.whiteColor,
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
                  color: ui.textMuted,
                  fontSize: FontSizes.font12Sp,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    AppText(
                      value,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font19Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    if (unit.isNotEmpty) ...[
                      4.horizontalSpace,
                      AppText(
                        unit,
                        color: ui.textSecondary,
                        fontSize: FontSizes.font15Sp,
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

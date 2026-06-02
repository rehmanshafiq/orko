import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripSummaryMetricWidget extends StatelessWidget {
  const TripSummaryMetricWidget({
    required this.icon,
    required this.label,
    required this.value,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12.sp, color: ui.textSecondary),
            4.horizontalSpace,
            Flexible(
              child: AppText(
                label,
                color: ui.textMuted,
                fontSize: FontSizes.font9Sp,
                fontWeight: FontWeights.weight400,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        4.verticalSpace,
        AppText(
          value,
          color: ui.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class DistanceChipWidget extends StatelessWidget {
  const DistanceChipWidget({
    required this.text,
    super.key,
  });

  final String text;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.navigation_rounded, color: ui.textSecondary, size: 10.sp),
          4.horizontalSpace,
          AppText(
            text,
            color: ui.textPrimary,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Brand-colored "LIVE" pill shown on live charging-session surfaces (the
/// Active tab and the charging-status content embedded there).
class LiveBadge extends StatelessWidget {
  const LiveBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(width: 1.w, color: ui.brandPrimary),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 7.r,
            width: 7.r,
            decoration: BoxDecoration(
              color: ui.brandPrimary,
              shape: BoxShape.circle,
            ),
          ),
          6.horizontalSpace,
          AppText(
            'LIVE',
            color: ui.brandPrimary,
            fontSize: FontSizes.font11Sp,
            fontWeight: FontWeights.weight700,
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// "Walk-in" pill shown on live charging sessions that were started without a
/// booking. Uses a blue accent so it reads distinctly from the green LIVE
/// badge sitting alongside it.
class WalkinBadge extends StatelessWidget {
  const WalkinBadge({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    const accent = AppColors.mapPinBlueColor;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(width: 1.w, color: ui.textMuted),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.directions_walk_rounded,
            color: ui.textMuted,
            size: 13.r,
          ),
          4.horizontalSpace,
          AppText(
            'Walk-in',
            color: ui.textMuted,
            fontSize: FontSizes.font11Sp,
            fontWeight: FontWeights.weight700,
          ),
        ],
      ),
    );
  }
}

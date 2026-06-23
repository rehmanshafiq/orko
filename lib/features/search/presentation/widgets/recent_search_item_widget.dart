import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class RecentSearchItemWidget extends StatelessWidget {
  const RecentSearchItemWidget({
    required this.text,
    this.onTap,
    this.onRemove,
    super.key,
  });

  final String text;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(Icons.access_time_rounded, color: ui.textMuted, size: 16.sp),
          10.horizontalSpace,
          Expanded(
            child: AppText(
              text,
              color: ui.textPrimary.withValues(alpha: 0.9),
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          10.horizontalSpace,
          if (onRemove != null)
            InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: Padding(
                padding: EdgeInsets.all(2.r),
                child: Icon(Icons.close_rounded, color: ui.textMuted, size: 16.sp),
              ),
            )
          else
            Icon(Icons.arrow_forward_ios_rounded,
                color: ui.textMuted, size: 13.sp),
        ],
      ),
    );
  }
}

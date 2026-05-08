import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class SearchSectionTitleWidget extends StatelessWidget {
  const SearchSectionTitleWidget({
    required this.title,
    this.leadingIcon,
    super.key,
  });

  final String title;
  final IconData? leadingIcon;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: AppColors.maroonColor, size: 16.sp),
          6.horizontalSpace,
        ],
        AppText(
          title,
          color: ui.textPrimary,
          fontSize: FontSizes.font20Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }
}


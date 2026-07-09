import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

/// Inline red banner shown under the top bar when the map fails to load.
class HomeErrorBannerWidget extends StatelessWidget {
  const HomeErrorBannerWidget(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 10.w),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.28)),
      ),
      child: AppText(
        message,
        color: AppUiColors.of(context).textPrimary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}

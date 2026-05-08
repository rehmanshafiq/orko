import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class TripHeaderWidget extends StatelessWidget {
  const TripHeaderWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        Icon(Icons.arrow_back_rounded, color: ui.textPrimary, size: 20.sp),
        8.horizontalSpace,
        AppText(
          'Trip Planner',
          color: ui.textPrimary,
          fontSize: FontSizes.font22Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }
}


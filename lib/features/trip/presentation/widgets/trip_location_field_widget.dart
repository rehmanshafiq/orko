import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';

class TripLocationFieldWidget extends StatelessWidget {
  const TripLocationFieldWidget({
    required this.controller,
    required this.isStart,
    super.key,
  });

  final TextEditingController controller;
  final bool isStart;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on_rounded,
            size: 14.sp,
            color: isStart ? AppColors.primaryDarkColor : AppColors.removeColor,
          ),
          8.horizontalSpace,
          Expanded(
            child: TextField(
              controller: controller,
              textInputAction: isStart ? TextInputAction.next : TextInputAction.done,
              keyboardType: TextInputType.streetAddress,
              style: TextStyle(
                color: ui.textPrimary.withValues(alpha: 0.9),
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight500,
              ),
              cursorColor: AppColors.primaryDarkColor,
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


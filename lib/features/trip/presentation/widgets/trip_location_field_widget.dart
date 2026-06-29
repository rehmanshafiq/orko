import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';

class TripLocationFieldWidget extends StatelessWidget {
  const TripLocationFieldWidget({
    required this.controller,
    required this.isStart,
    this.onTap,
    super.key,
  });

  final TextEditingController controller;
  final bool isStart;

  /// Tapping the field opens the Google Places search sheet. When provided the
  /// text field becomes read-only so editing happens only via place selection.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        padding: AppUtils.vertical10Horizontal12Padding,
        decoration: BoxDecoration(
          color: ui.searchBackground,
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(color: ui.borderSubtle),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_rounded,
              size: 14.sp,
              color: isStart ? ui.brandPrimary : AppColors.removeColor,
            ),
            8.horizontalSpace,
            Expanded(
              child: TextField(
                controller: controller,
                readOnly: onTap != null,
                onTap: onTap,
                textInputAction:
                    isStart ? TextInputAction.next : TextInputAction.done,
                keyboardType: TextInputType.streetAddress,
                style: TextStyle(
                  color: ui.textPrimary.withValues(alpha: 0.9),
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                ),
                cursorColor: ui.brandPrimary,
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                  hintText: isStart ? 'Choose start location' : 'Choose destination',
                  hintStyle: TextStyle(
                    color: ui.textPrimary.withValues(alpha: 0.4),
                    fontSize: FontSizes.font12Sp,
                    fontWeight: FontWeights.weight500,
                  ),
                ),
              ),
            ),
            8.horizontalSpace,
            Icon(
              Icons.search_rounded,
              size: 16.sp,
              color: ui.textPrimary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}


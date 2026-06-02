import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

class ChargingStationBottomActionsWidget extends StatelessWidget {
  const ChargingStationBottomActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 12.h),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: ui.textPrimary,
                  side: BorderSide(
                    color: ui.textPrimary.withValues(alpha: 0.85),
                  ),
                  padding: EdgeInsets.symmetric(vertical: 14.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(32.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.navigation_rounded, size: 18.r),
                    8.horizontalSpace,
                    AppText(
                      'Directions',
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ],
                ),
              ),
            ),
            12.horizontalSpace,
            Expanded(
              child: PrimaryButtonWidget(
                text: 'Book Slot',
                leadingIcon: Icons.calendar_today_outlined,
                iconHeight: 18.sp,
                onPress: () => context.go('/bookings'),
                buttonWidth: double.infinity,
                buttonHeight: 48.h,
                cornerRadius: 32.r,
                buttonColor: AppColors.primaryDarkColor,
                textColor: AppColors.whiteColor,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

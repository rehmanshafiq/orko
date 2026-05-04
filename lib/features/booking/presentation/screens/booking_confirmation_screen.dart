import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';

/// Shown after successful payment — booking summary & return to bookings.
class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({
    super.key,
    this.amountPaid = 472,
  });

  final int amountPaid;

  static const String _bookingRef = 'BK-2025-04182';
  static const String _stationName = 'HGL Charging Hub M2';
  static const String _slotLabel = 'April 18 · 14:00 – 15:00';
  static const String _paymentLabel = 'Visa •••• 4242';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: AppUtils.horizontal16Padding,
                child: Column(
                  children: [
                    36.verticalSpace,
                    Container(
                      height: 88.r,
                      width: 88.r,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryDarkColor.withValues(alpha: 0.2),
                        border: Border.all(
                          color: AppColors.primaryDarkColor,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: AppColors.primaryDarkColor,
                        size: 48.r,
                      ),
                    ),
                    22.verticalSpace,
                    AppText(
                      'Booking Confirmed!',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font24Sp,
                      fontWeight: FontWeights.weight700,
                      textAlign: TextAlign.center,
                    ),
                    10.verticalSpace,
                    AppText(
                      'Your charging slot is reserved. A receipt has been sent to your email.',
                      color: AppColors.iconsGreyColor,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight400,
                      textAlign: TextAlign.center,
                    ),
                    28.verticalSpace,
                    Container(
                      width: double.infinity,
                      padding: AppUtils.all18Padding,
                      decoration: BoxDecoration(
                        color: AppColors.fieldBackgroundColor,
                        borderRadius: BorderRadius.circular(14.r),
                        border: Border.all(
                          color: AppColors.whiteColor.withValues(alpha: 0.08),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _detailRow('Booking ID', _bookingRef, emphasizeValue: true),
                          14.verticalSpace,
                          Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.whiteColor.withValues(alpha: 0.08),
                          ),
                          14.verticalSpace,
                          _detailRow('Station', _stationName),
                          12.verticalSpace,
                          _detailRow('Slot', _slotLabel),
                          12.verticalSpace,
                          _detailRow('Amount paid', 'Rs $amountPaid'),
                          12.verticalSpace,
                          _detailRow('Payment', _paymentLabel),
                        ],
                      ),
                    ),
                    20.verticalSpace,
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(
                        horizontal: 14.w,
                        vertical: 12.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDarkColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: AppColors.primaryDarkColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AppColors.primaryDarkColor,
                            size: 20.r,
                          ),
                          10.horizontalSpace,
                          Expanded(
                            child: AppText(
                              'Arrive 5 minutes early. You can modify or cancel from Bookings before your slot starts.',
                              color: AppColors.whiteColor.withValues(alpha: 0.88),
                              fontSize: FontSizes.font12Sp,
                              fontWeight: FontWeights.weight400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    24.verticalSpace,
                  ],
                ),
              ),
            ),
            Padding(
              padding: AppUtils.horizontal16Padding.add(
                EdgeInsets.only(bottom: 12.h, top: 8.h),
              ),
              child: PrimaryButtonWidget(
                text: 'Start Charge',
                onPress: () => context.go('/profile'),
                buttonWidth: double.infinity,
                buttonHeight: 52.h,
                cornerRadius: 12.r,
                buttonColor: AppColors.primaryDarkColor,
                textColor: AppColors.whiteColor,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    String label,
    String value, {
    bool emphasizeValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: AppText(
            label,
            color: AppColors.iconsGreyColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ),
        12.horizontalSpace,
        Expanded(
          flex: 3,
          child: AppText(
            value,
            color: emphasizeValue
                ? AppColors.primaryDarkColor
                : AppColors.whiteColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: emphasizeValue
                ? FontWeights.weight700
                : FontWeights.weight600,
            textAlign: TextAlign.end,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

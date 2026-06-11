import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

class UpcomingBookingCard extends StatelessWidget {
  const UpcomingBookingCard({
    super.key,
    required this.ui,
    required this.booking,
    required this.onModify,
    required this.onCancel,
  });

  final AppUiColors ui;
  final UpcomingBooking booking;
  final VoidCallback onModify;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ui.brandPrimary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 44.r,
                width: 44.r,
                decoration: BoxDecoration(
                  color: ui.brandPrimary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: ui.brandPrimary,
                  size: 22.sp,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      booking.stationName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font16Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      booking.powerLabel,
                      color: ui.textSecondary,
                      fontSize: FontSizes.font13Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              _StatusBadge(ui: ui, label: booking.statusLabel),
            ],
          ),
          16.verticalSpace,
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: ui.textSecondary,
                size: 16.sp,
              ),
              6.horizontalSpace,
              Expanded(
                child: AppText(
                  booking.dateTimeLabel,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font13Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ),
              8.horizontalSpace,
              Icon(
                Icons.access_time_rounded,
                color: ui.textSecondary,
                size: 16.sp,
              ),
              6.horizontalSpace,
              AppText(
                booking.durationLabel,
                color: ui.textSecondary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight400,
              ),
            ],
          ),
          14.verticalSpace,
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
            decoration: BoxDecoration(
              color: ui.brandPrimary.withValues(alpha: ui.isLight ? 0.1 : 0.18),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppText(
                  'Estimated Cost',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight500,
                ),
                AppText(
                  booking.estimatedCost.toString(),
                  color: ui.textPrimary,
                  fontSize: FontSizes.font16Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ],
            ),
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: PrimaryButtonWidget(
                  text: 'Modify',
                  onPress: onModify,
                  buttonHeight: 38.h,
                  cornerRadius: 12.r,
                  strokeColor: ui.borderSubtle,
                  buttonColor: ui.cardBackground,
                  textColor: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: PrimaryButtonWidget(
                  text: 'Cancel',
                  onPress: onCancel,
                  buttonHeight: 38.h,
                  cornerRadius: 12.r,
                  strokeColor: AppColors.removeColor,
                  buttonColor: ui.cardBackground,
                  textColor: AppColors.removeColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.ui, required this.label});

  final AppUiColors ui;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        color: AppColors.transparentColor,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: ui.brandPrimary),
      ),
      child: AppText(
        label,
        color: ui.brandPrimary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}

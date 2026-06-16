import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

class HistoryBookingCard extends StatelessWidget {
  const HistoryBookingCard({
    super.key,
    required this.ui,
    required this.booking,
  });

  final AppUiColors ui;
  final HistoryBooking booking;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
              Container(
                height: 44.r,
                width: 44.r,
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  shape: BoxShape.circle,
                  border: Border.all(color: ui.iconContainerOutline, width: 1.5),
                ),
                child: Icon(
                  Icons.bolt,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      booking.dateTimeLabel,
                      color: ui.textSecondary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                    4.verticalSpace,
                    Row(
                      children: [
                        AppText(
                          booking.relativeLabel,
                          color: ui.textSecondary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        AppText(
                          '  ·  ',
                          color: ui.textSecondary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                        AppText(
                          '${booking.energyKwh} kWh',
                          color: ui.brandPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight600,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _CompletedBadge(label: booking.statusLabel),
                  10.verticalSpace,
                  AppText(
                    'PKR ${booking.amount.toStringAsFixed(2)}',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font16Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ],
              ),
            ],
      ),
    );
  }
}

class _CompletedBadge extends StatelessWidget {
  const _CompletedBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        // color: ui.brandSecondary,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(width: 1.w, color: ui.brandSecondary)
      ),
      child: AppText(
        label,
        color: ui.textSecondary,
        fontSize: FontSizes.font11Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }
}

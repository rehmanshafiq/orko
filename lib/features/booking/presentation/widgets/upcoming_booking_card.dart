import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/domain/entities/my_booking_entity.dart';

class UpcomingBookingCard extends StatelessWidget {
  const UpcomingBookingCard({
    super.key,
    required this.ui,
    required this.booking,
    required this.onModify,
    required this.onCancel,
    required this.onScanQr,
    this.isProcessing = false,
    this.showActions = true,
  });

  final AppUiColors ui;
  final MyBookingEntity booking;
  final VoidCallback onModify;
  final VoidCallback onCancel;
  final VoidCallback onScanQr;

  /// True while a cancel/reschedule call for this booking is in flight.
  final bool isProcessing;

  /// When false (e.g. cancelled bookings), the Scan QR / Modify / Cancel
  /// controls are hidden and the card renders as a read-only summary.
  final bool showActions;

  String get _powerLabel {
    final info = booking.chargerInfo;
    if (info == null) return 'Charging slot';
    final parts = <String>[
      if (info.connectorType.isNotEmpty) info.connectorType,
      if (info.power.isNotEmpty) info.power,
      if (info.powerType.isNotEmpty) info.powerType.toUpperCase(),
    ];
    return parts.isEmpty ? 'Charging slot' : parts.join(' · ');
  }

  String get _statusLabel {
    final s = booking.bookingStatus;
    if (s.isEmpty) return '—';
    return s[0].toUpperCase() + s.substring(1);
  }

  String get _costLabel {
    final cost = booking.estimatedCost;
    if (cost == null) return 'N/A';
    final amount = cost.amount;
    final fixed = amount.toStringAsFixed(2);
    final trimmed =
        fixed.endsWith('.00') ? fixed.substring(0, fixed.length - 3) : fixed;
    final currency = cost.currency.isEmpty ? 'PKR' : cost.currency;
    return '$currency $trimmed';
  }

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
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12.r),
                  border: Border.all(
                    color: ui.isLight ? ui.iconContainerOutline : ui.brandPrimary,
                    width: 1.5,
                  ),
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
                      booking.displayName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font16Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      _powerLabel,
                      color: ui.textSecondary,
                      fontSize: FontSizes.font13Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              _StatusBadge(ui: ui, label: _statusLabel),
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
                  booking.date,
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
                '${booking.startTime} - ${booking.endTime}',
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
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: ui.isLight ? ui.iconContainerOutline : ui.brandPrimary,
                width: 1.5,
              ),
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
                  _costLabel,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font16Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ],
            ),
          ),
          if (showActions) ...[
            16.verticalSpace,
            PrimaryButtonWidget(
              text: 'Scan QR Code',
              leadingIcon: Icons.qr_code_scanner_rounded,
              onPress: onScanQr,
              isEnabled: !isProcessing,
              buttonHeight: 38.h,
              cornerRadius: 24.r,
              gradientColors: const [
                AppColors.primaryDarkColor,
                AppColors.primaryDarkButtonColor,
              ],
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight700,
            ),
            16.verticalSpace,
            if (isProcessing)
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  child: SizedBox(
                    width: 22.w,
                    height: 22.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: ui.brandPrimary,
                    ),
                  ),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: PrimaryButtonWidget(
                      text: 'Modify',
                      onPress: onModify,
                      buttonHeight: 38.h,
                      cornerRadius: 12.r,
                      strokeColor: ui.iconContainerOutline,
                      buttonColor: ui.cardBackground,
                      textColor: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
                  if (booking.canCancel) ...[
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
                ],
              ),
          ],
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
        color: ui.textSecondary,
        fontSize: FontSizes.font12Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}

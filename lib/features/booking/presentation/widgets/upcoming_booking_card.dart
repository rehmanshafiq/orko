import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
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
    this.showScanQr = true,
    this.showModify = true,
  });

  final AppUiColors ui;
  final MyBookingEntity booking;
  final VoidCallback onModify;
  final VoidCallback onCancel;
  final VoidCallback onScanQr;

  /// True while a cancel/reschedule call for this booking is in flight.
  final bool isProcessing;

  /// Whether to show the "Scan QR Code" button (only for approved bookings).
  final bool showScanQr;

  /// Whether to show the "Modify" button (only for approved bookings).
  /// The "Cancel" button is shown independently when [MyBookingEntity.canCancel]
  /// is true, so pending bookings can still be cancelled.
  final bool showModify;

  String get _powerLabel {
    final info = booking.chargerInfo;
    if (info == null) return 'Charging slot';
    final parts = <String>[
      if (info.connectorType.isNotEmpty) info.connectorType,
      if (info.power.isNotEmpty) AppHelpers.formatPower(info.power),
      if (info.powerType.isNotEmpty) info.powerType.toUpperCase(),
    ];
    return parts.isEmpty ? 'Charging slot' : parts.join(' · ');
  }

  String get _statusLabel {
    final s = booking.bookingStatus.trim();
    if (s.isEmpty) return '—';
    // Turn `pending_approval` → `Pending Approval`, `approved` → `Approved`.
    return s
        .split('_')
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  String get _costLabel {
    final cost = booking.estimatedCost;
    if (cost == null) return 'N/A';
    final currency = cost.currency.isEmpty ? 'PKR' : cost.currency;
    return AppHelpers.formatCurrency(cost.amount, currency: currency);
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
                    color: AppColors.greyColor,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.calendar_today_outlined,
                  color: ui.isLight
                      ? AppColors.blackColor
                      : AppColors.whiteColor,
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
              // Approved bookings don't need a badge — the Scan QR/Modify
              // actions already imply it. Pending/Cancelled keep theirs.
              if (!booking.isApproved) ...[
                8.horizontalSpace,
                _StatusBadge(ui: ui, label: _statusLabel),
              ],
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
                  booking.displayDate,
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
          12.verticalSpace,
          AppText(
            'Estimated Cost: $_costLabel',
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
          ),
          // Scan QR (approved only) — grey rounded pill per design.
          if (showScanQr) ...[
            16.verticalSpace,
            _GreyPillButton(
              ui: ui,
              label: 'Scan QR Code',
              leadingIcon: Icons.qr_code_scanner_rounded,
              onPressed: onScanQr,
              isEnabled: !isProcessing,
            ),
          ],
          // Modify / Cancel row — rendered only if at least one is available.
          if (showModify || booking.canCancel) ...[
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
                  if (showModify)
                    Expanded(
                      child: _OutlinedActionButton(
                        ui: ui,
                        label: 'Modify',
                        onPressed: onModify,
                      ),
                    ),
                  if (showModify && booking.canCancel) 12.horizontalSpace,
                  if (booking.canCancel)
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
        ],
      ),
    );
  }
}

/// Filled grey rounded pill button — used for "Scan QR Code".
class _GreyPillButton extends StatelessWidget {
  const _GreyPillButton({
    required this.ui,
    required this.label,
    required this.onPressed,
    this.leadingIcon,
    this.isEnabled = true,
  });

  final AppUiColors ui;
  final String label;
  final VoidCallback onPressed;
  final IconData? leadingIcon;
  final bool isEnabled;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: TextButton(
        onPressed: isEnabled ? onPressed : null,
        style: ButtonStyle(
          backgroundColor: WidgetStatePropertyAll(
            ui.isLight
                ? AppColors.shimmerGreyColor
                : AppColors.whiteColor.withValues(alpha: 0.08),
          ),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(19.r),
            ),
          ),
          overlayColor: WidgetStatePropertyAll(
            ui.textPrimary.withValues(alpha: 0.06),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12.w),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcon != null) ...[
              Icon(leadingIcon, color: ui.textPrimary, size: 18.sp),
              8.horizontalSpace,
            ],
            Flexible(
              child: AppText(
                label,
                color: ui.textPrimary,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Outlined action button: no fill, grey outline at rest, and a brand-green
/// outline while the button is selected (pressed/focused/hovered). Used for
/// "Modify".
class _OutlinedActionButton extends StatelessWidget {
  const _OutlinedActionButton({
    required this.ui,
    required this.label,
    required this.onPressed,
  });

  final AppUiColors ui;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38.h,
      child: OutlinedButton(
        onPressed: onPressed,
        style: ButtonStyle(
          backgroundColor:
              const WidgetStatePropertyAll(AppColors.transparentColor),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.greyColor);
            }
            final selected = states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.focused) ||
                states.contains(WidgetState.hovered);
            return BorderSide(
              color: selected ? ui.brandPrimary : AppColors.greyColor,
            );
          }),
          overlayColor: WidgetStatePropertyAll(
            ui.brandPrimary.withValues(alpha: 0.08),
          ),
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 12.w),
          ),
        ),
        child: AppText(
          label,
          textAlign: TextAlign.center,
          color: ui.textPrimary,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight700,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
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

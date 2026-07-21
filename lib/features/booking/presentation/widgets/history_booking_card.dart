import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';

class HistoryBookingCard extends StatelessWidget {
  const HistoryBookingCard({
    super.key,
    required this.ui,
    required this.booking,
    this.onTap,
  });

  final AppUiColors ui;
  final HistoryBooking booking;

  /// Tapping the card opens the session summary for this row.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final energyLabel =
        booking.energyKwh != null ? '${_trim(booking.energyKwh!)} kWh' : '—';
    final amountLabel = booking.amount != null
        ? AppHelpers.formatCurrency(booking.amount!.roundToDouble())
        : '—';

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ui.borderSubtle),
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
                  shape: BoxShape.circle,
                  border: Border.all(
                    color:
                        ui.isLight ? ui.iconContainerOutline : ui.brandPrimary,
                    width: 1.5,
                  ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              _StatusBadge(
                label: booking.statusLabel,
                isInProgress: booking.isInProgress,
              ),
            ],
          ),
          12.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _SessionTypeBadge(ui: ui, isWalkIn: booking.isWalkIn),
              const Spacer(),
              AppText(
                amountLabel,
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  /// Drops a trailing `.0` so `0.45` stays but `12.0` shows as `12`.
  String _trim(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }
}

/// Small pill marking how the session started: a walk-in (no booking) or a
/// booked session (reserved beforehand).
class _SessionTypeBadge extends StatelessWidget {
  const _SessionTypeBadge({required this.ui, required this.isWalkIn});

  final AppUiColors ui;
  final bool isWalkIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(width: 1.w, color: ui.textMuted),
      ),
      child: AppText(
        isWalkIn ? 'Walk-in' : 'Booked session',
        color: ui.textMuted,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.isInProgress});

  final String label;
  final bool isInProgress;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    // In-progress sessions get the brand-primary accent; completed/other use
    // the secondary accent, matching the rest of the booking UI.
    final accent = isInProgress ? ui.brandPrimary : ui.brandSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 5.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(width: 1.w, color: accent),
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

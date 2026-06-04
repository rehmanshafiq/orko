import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

class ChargingStationAvailabilityBadgeWidget extends StatelessWidget {
  const ChargingStationAvailabilityBadgeWidget({
    super.key,
    required this.station,
    required this.available,
    required this.total,
  });

  final HubcoLocationEntity station;
  final int available;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final label = station.status
        ? 'Available $available of $total'
        : 'Unavailable';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: station.status
            ? (ui.isLight ? ui.brandPrimary : ui.brandSecondary)
                .withValues(alpha: ui.isLight ? 0.22 : 0.38)
            : AppColors.slotBookedBackgroundColor.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: AppText(
        label,
        color: station.status ? ui.brandPrimary : ui.textSecondary,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
        maxLines: 2,
        textAlign: TextAlign.end,
      ),
    );
  }
}

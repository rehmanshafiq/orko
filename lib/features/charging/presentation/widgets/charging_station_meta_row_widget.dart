import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_availability_badge_widget.dart';
import 'package:orko_hubco/features/charging/presentation/widgets/charging_station_meta_item_widget.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

class ChargingStationMetaRowWidget extends StatelessWidget {
  const ChargingStationMetaRowWidget({
    super.key,
    required this.station,
    required this.availableCount,
    required this.totalPorts,
  });

  final HubcoLocationEntity station;
  final int availableCount;
  final int totalPorts;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Wrap(
      spacing: 8.w,
      runSpacing: 8.h,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ChargingStationMetaItemWidget(
          icon: Icons.star_rounded,
          text: '4.8 (127 reviews)',
          iconColor: AppColors.ratingStarColor,
          textColor: ui.textSecondary,
          textFontWeight: FontWeights.weight500,
        ),
        ChargingStationMetaItemWidget(
          icon: Icons.location_on_rounded,
          text: '2.3 km',
          iconColor: AppColors.mapPinBlueColor,
          textColor: AppColors.mapPinBlueColor,
          textFontWeight: FontWeights.weight600,
        ),
        ChargingStationAvailabilityBadgeWidget(
          station: station,
          available: availableCount,
          total: totalPorts,
        ),
      ],
    );
  }
}

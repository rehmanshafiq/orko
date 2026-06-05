import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Wrap(
            spacing: 8.w,
            runSpacing: 8.h,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.star_rounded,
                    color: AppColors.ratingStarColor,
                    size: 18.r,
                  ),
                  4.horizontalSpace,
                  AppText(
                    '4.8',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font12Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                  4.horizontalSpace,
                  AppText(
                    '(127 reviews)',
                    color: ui.textSecondary,
                    fontSize: FontSizes.font12Sp,
                    fontWeight: FontWeights.weight500,
                  ),
                ],
              ),
              ChargingStationMetaItemWidget(
                icon: Icons.location_on_rounded,
                text: '2.3 km',
                iconColor: AppColors.mapPinBlueColor,
                textColor: AppColors.mapPinBlueColor,
                textFontWeight: FontWeights.weight600,
              ),
            ],
          ),
        ),
        8.horizontalSpace,
        // ChargingStationAvailabilityBadgeWidget(
        //   station: station,
        //   available: availableCount,
        //   total: totalPorts,
        // ),
      ],
    );
  }
}

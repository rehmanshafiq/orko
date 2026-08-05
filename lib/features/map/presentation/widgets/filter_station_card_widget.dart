import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/widgets/station_label_helpers.dart';
import 'package:orko_hubco/features/map/presentation/widgets/station_plug_icons_row_widget.dart';

/// Full-width station card in the filter results list. Tapping it closes the
/// screen and focuses the tapped station on the home map (via [onTap]).
class FilterStationCardWidget extends StatelessWidget {
  const FilterStationCardWidget(
    this.station, {
    super.key,
    required this.onTap,
  });

  final HubcoLocationEntity station;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    // final locationLabel = stationLocationLabel(station);
    // final title = station.displayName.isNotEmpty
    //     ? station.displayName
    //     : (locationLabel.isNotEmpty ? locationLabel : station.name);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24.r),
        child: Ink(
          padding: EdgeInsets.fromLTRB(14.w, 12.h, 14.w, 4.h),
          decoration: BoxDecoration(
            color: ui.innerCardBg,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: ui.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: AppText(
                      station.displayName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  8.horizontalSpace,
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: AppColors.whiteColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_rounded,
                          color: ui.textPrimary,
                          size: 10.sp,
                        ),
                        4.horizontalSpace,
                        AppText(
                          stationDistanceLabel(station),
                          color: ui.textPrimary,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight500,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // if (locationLabel.isNotEmpty) ...[
                5.verticalSpace,
                AppText(
                  station.name,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font13Sp,
                  fontWeight: FontWeights.weight500,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              // ],
              4.verticalSpace,
              AppText(
                stationAvailabilityLabel(station),
                color: ui.textSecondary,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight500,
              ),
              8.verticalSpace,
              Row(
                children: [
                  StationPlugIconsRowWidget(
                    color: ui.textSecondary,
                    powerLabel: stationPowerLabel(station),
                  ),
                  const Spacer(),
                  Flexible(
                    child: AppText(
                      stationPriceLabel(station),
                      color: ui.textSecondary,
                      fontSize: FontSizes.font13Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  16.horizontalSpace,
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

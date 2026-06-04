import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/trip/presentation/models/stop_charge_info_model.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_amenity_chip_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stop_metric_widget.dart';

class TripChargingStopCardWidget extends StatelessWidget {
  const TripChargingStopCardWidget({
    required this.stopIndex,
    required this.station,
    required this.info,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onViewDetails,
    required this.onPreBook,
    required this.formatPkr,
    super.key,
  });

  final int stopIndex;
  final HubcoLocationEntity station;
  final StopChargeInfoModel info;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onViewDetails;
  final VoidCallback onPreBook;
  final String Function(int) formatPkr;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.searchBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ui.brandPrimary,
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      station.name,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      station.address,
                      color: ui.textMuted,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              4.horizontalSpace,
              GestureDetector(
                onTap: onToggleExpanded,
                behavior: HitTestBehavior.opaque,
                child: Padding(
                  padding: AppUtils.all4Padding,
                  child: Icon(
                    expanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    size: 22.sp,
                    color: ui.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Row(
            children: [
              Expanded(
                child: TripChargingStopMetricWidget(
                  label: 'Arrive',
                  value: '${info.arrivePct}%',
                  valueColor: AppColors.ratingStarColor,
                ),
              ),
              Expanded(
                child: TripChargingStopMetricWidget(
                  label: 'Depart',
                  value: '${info.departPct}%',
                  valueColor: ui.brandPrimary,
                ),
              ),
              Expanded(
                child: TripChargingStopMetricWidget(
                  label: 'Time',
                  value: '${info.minutes} min',
                  valueColor: ui.textPrimary,
                ),
              ),
              Expanded(
                child: TripChargingStopMetricWidget(
                  label: 'Cost',
                  value: formatPkr(info.costPkr),
                  valueColor: ui.textPrimary,
                ),
              ),
            ],
          ),
          if (expanded) ...[
            14.verticalSpace,
            AppText(
              'Amenities',
              color: ui.textPrimary,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight600,
            ),
            8.verticalSpace,
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  const TripChargingAmenityChipWidget(
                    icon: Icons.wifi_rounded,
                    label: 'WiFi',
                  ),
                  8.horizontalSpace,
                  const TripChargingAmenityChipWidget(
                    icon: Icons.wc_rounded,
                    label: 'Restroom',
                  ),
                  8.horizontalSpace,
                  const TripChargingAmenityChipWidget(
                    icon: Icons.local_cafe_rounded,
                    label: 'Food',
                  ),
                  8.horizontalSpace,
                  const TripChargingAmenityChipWidget(
                    icon: Icons.shopping_bag_outlined,
                    label: 'Shopping',
                  ),
                ],
              ),
            ),
            14.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'View Details',
                    onPress: onViewDetails,
                    buttonWidth: double.infinity,
                    buttonHeight: 40.h,
                    cornerRadius: 8.r,
                    buttonColor: ui.cardBackground,
                    strokeColor: ui.inputBorder,
                    textColor: ui.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
                8.horizontalSpace,
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'Pre-book',
                    onPress: onPreBook,
                    buttonWidth: double.infinity,
                    buttonHeight: 40.h,
                    cornerRadius: 8.r,
                    buttonColor: ui.cardBackground,
                    strokeColor: ui.inputBorder,
                    textColor: ui.textPrimary,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight600,
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


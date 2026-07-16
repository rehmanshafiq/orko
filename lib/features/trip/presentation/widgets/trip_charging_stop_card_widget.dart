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
    required this.onNavigate,
    required this.formatPkr,
    this.booked = false,
    super.key,
  });

  final int stopIndex;
  final HubcoLocationEntity station;
  final StopChargeInfoModel info;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onViewDetails;
  final VoidCallback onPreBook;

  /// Opens the user's preferred maps app with directions to this station.
  final VoidCallback onNavigate;
  final String Function(int) formatPkr;

  /// True when the user already booked this station in this session — the
  /// Pre-book button then reads "Booked" and is disabled.
  final bool booked;

  /// Maps an amenity label to a representative icon, falling back to a generic
  /// check mark for anything not explicitly recognised.
  IconData _amenityIcon(String amenity) {
    final key = amenity.toLowerCase().trim();
    if (key.contains('wifi') || key.contains('wi-fi')) return Icons.wifi_rounded;
    if (key.contains('air') || key.contains('ac') || key.contains('a/c')) {
      return Icons.ac_unit_rounded;
    }
    if (key.contains('restroom') ||
        key.contains('toilet') ||
        key.contains('washroom')) {
      return Icons.wc_rounded;
    }
    if (key.contains('food') ||
        key.contains('cafe') ||
        key.contains('coffee') ||
        key.contains('restaurant')) {
      return Icons.local_cafe_rounded;
    }
    if (key.contains('shop') || key.contains('store') || key.contains('market')) {
      return Icons.shopping_bag_outlined;
    }
    if (key.contains('park')) return Icons.local_parking_rounded;
    if (key.contains('charg')) return Icons.ev_station_rounded;
    return Icons.check_circle_outline_rounded;
  }

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
                  label: 'Est. Charging Time',
                  value: '${info.minutes} min',
                  valueColor: ui.textPrimary,
                ),
              ),
              20.horizontalSpace,
              Expanded(
                child: TripChargingStopMetricWidget(
                  label: 'Est. Cost',
                  value: formatPkr(info.costPkr),
                  valueColor: ui.textPrimary,
                ),
              ),
            ],
          ),
          if (info.distanceFromPreviousStopKm != null) ...[
            10.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: TripChargingStopMetricWidget(
                    label: 'Distance from previous stop',
                    value:
                        '${info.distanceFromPreviousStopKm!.toStringAsFixed(2)} km',
                    valueColor: ui.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          if (expanded) ...[
            if (info.amenities.isNotEmpty) ...[
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
                    for (var i = 0; i < info.amenities.length; i++) ...[
                      if (i > 0) 8.horizontalSpace,
                      TripChargingAmenityChipWidget(
                        icon: _amenityIcon(info.amenities[i]),
                        label: info.amenities[i],
                      ),
                    ],
                  ],
                ),
              ),
            ],
            14.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'View Details',
                    onPress: onViewDetails,
                    // Disabled once the stop is booked, matching Pre-book.
                    isEnabled: !booked,
                    buttonWidth: double.infinity,
                    buttonHeight: 38.h,
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
                    text: booked ? 'Booked' : 'Pre-book',
                    onPress: onPreBook,
                    // A booked stop can't be pre-booked again from here.
                    isEnabled: !booked,
                    buttonWidth: double.infinity,
                    buttonHeight: 38.h,
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
            8.verticalSpace,
            // Opens the user's preferred maps app with directions to this stop.
            // Stays enabled for booked stops — you still need to get there.
            PrimaryButtonWidget(
              text: 'Navigate',
              onPress: onNavigate,
              buttonWidth: double.infinity,
              buttonHeight: 38.h,
              cornerRadius: 8.r,
              buttonColor: ui.cardBackground,
              strokeColor: ui.inputBorder,
              textColor: ui.textPrimary,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight600,
            ),
          ],
        ],
      ),
    );
  }
}


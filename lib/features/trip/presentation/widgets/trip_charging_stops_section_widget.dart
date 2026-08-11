import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stop_card_widget.dart';
// import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stops_timeline_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_section_title_widget.dart';

class TripChargingStopsSectionWidget extends StatelessWidget {
  const TripChargingStopsSectionWidget({
    required this.plan,
    required this.currentBatteryPercent,
    required this.targetArrivalBatteryPercent,
    required this.expandedChargingStopIndex,
    required this.onToggleChargingStop,
    required this.onViewDetails,
    required this.onPreBook,
    required this.onNavigate,
    required this.formatPkr,
    this.bookedStationIds = const <int>{},
    this.showTitle = true,
    super.key,
  });

  final TripPlanModel? plan;
  final double currentBatteryPercent;
  final double targetArrivalBatteryPercent;
  final int? expandedChargingStopIndex;
  final ValueChanged<int> onToggleChargingStop;
  final ValueChanged<int> onViewDetails;
  final ValueChanged<int> onPreBook;

  /// Opens the user's preferred maps app with directions to the stop at index.
  final ValueChanged<int> onNavigate;
  final String Function(int) formatPkr;

  /// Station ids booked this session — their stop cards show "Booked".
  final Set<int> bookedStationIds;

  /// Whether to render the "Suggested Stops" heading. Hidden when a tab label
  /// already serves as the section header.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showTitle) ...[
          const TripSectionTitleWidget(text: 'Suggested Stops'),
          14.verticalSpace,
        ],
        if (plan == null)
          AppText(
            'Plan a trip to see charging stops along your route.',
            color: ui.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < plan!.stops.length; i++) ...[
                if (i > 0) 8.verticalSpace,
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TripChargingStopCardWidget(
                        stopIndex: i,
                        station: plan!.stops[i],
                        info: plan!.chargeInfo[i],
                        expanded: expandedChargingStopIndex == i,
                        onToggleExpanded: () => onToggleChargingStop(i),
                        onViewDetails: () => onViewDetails(i),
                        onPreBook: () => onPreBook(i),
                        onNavigate: () => onNavigate(i),
                        formatPkr: formatPkr,
                        booked: bookedStationIds.contains(plan!.stops[i].id),
                        isThirdParty: plan!.chargeInfo[i].isThirdParty,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        // TripChargingStopsTimelineWidget(
        //   plan: plan!,
        //   lineColor: lineColor,
        //   currentBatteryPercent: currentBatteryPercent,
        //   targetArrivalBatteryPercent: targetArrivalBatteryPercent,
        //   expandedChargingStopIndex: expandedChargingStopIndex,
        //   onToggleChargingStop: onToggleChargingStop,
        //   onViewDetails: onViewDetails,
        //   onPreBook: onPreBook,
        //   formatPkr: formatPkr,
        // ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stop_card_widget.dart';

class TripChargingStopsTimelineWidget extends StatelessWidget {
  const TripChargingStopsTimelineWidget({
    required this.plan,
    required this.lineColor,
    required this.currentBatteryPercent,
    required this.targetArrivalBatteryPercent,
    required this.expandedChargingStopIndex,
    required this.onToggleChargingStop,
    required this.onViewDetails,
    required this.onPreBook,
    required this.onNavigate,
    required this.formatPkr,
    super.key,
  });

  final TripPlanModel plan;
  final Color lineColor;
  final double currentBatteryPercent;
  final double targetArrivalBatteryPercent;
  final int? expandedChargingStopIndex;
  final ValueChanged<int> onToggleChargingStop;
  final ValueChanged<int> onViewDetails;
  final VoidCallback onPreBook;

  /// Opens the user's preferred maps app with directions to the stop at index.
  final ValueChanged<int> onNavigate;
  final String Function(int) formatPkr;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final rail = 38.w;
    final node = 24.w;

    Widget connector({double? height}) {
      return Center(
        child: Container(
          width: 2.w,
          height: height,
          decoration: BoxDecoration(
            color: lineColor,
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
      );
    }

    Widget flexibleConnector() => Expanded(child: connector());

    Widget circleNode({required Color backgroundColor, required Widget child}) {
      return Container(
        width: node,
        height: node,
        decoration: BoxDecoration(
          color: backgroundColor,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: child,
      );
    }

    Widget railColumn({required List<Widget> children}) {
      return Container(
        width: rail,
        alignment: Alignment.topCenter,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        ),
      );
    }

    Widget connectorRow() {
      return Row(
        children: [
          Container(
            width: rail,
            alignment: Alignment.center,
            child: connector(height: 14.h),
          ),
          10.horizontalSpace,
          Expanded(child: Container()),
        ],
      );
    }

    final children = <Widget>[
      IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            railColumn(
              children: [
                circleNode(
                  backgroundColor: ui.brandPrimary,
                  child: Icon(
                    Icons.location_on_rounded,
                    size: 12.sp,
                    color: AppColors.whiteColor,
                  ),
                ),
                4.verticalSpace,
                flexibleConnector(),
              ],
            ),
            10.horizontalSpace,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText(
                    plan.start.name,
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                  4.verticalSpace,
                  AppText(
                    'Starting point • ${currentBatteryPercent.round()}% battery',
                    color: ui.textMuted,
                    fontSize: FontSizes.font10Sp,
                    fontWeight: FontWeights.weight400,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];

    for (var i = 0; i < plan.stops.length; i++) {
      final station = plan.stops[i];
      final info = plan.chargeInfo[i];
      children
        ..add(connectorRow())
        ..add(
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                railColumn(
                  children: [
                    flexibleConnector(),
                    circleNode(
                      backgroundColor: AppColors.ratingStarColor,
                      child: Icon(
                        Icons.bolt_rounded,
                        size: 12.sp,
                        color: AppColors.whiteColor,
                      ),
                    ),
                    flexibleConnector(),
                  ],
                ),
                10.horizontalSpace,
                Expanded(
                  child: TripChargingStopCardWidget(
                    stopIndex: i,
                    station: station,
                    info: info,
                    expanded: expandedChargingStopIndex == i,
                    onToggleExpanded: () => onToggleChargingStop(i),
                    onViewDetails: () => onViewDetails(i),
                    onPreBook: onPreBook,
                    onNavigate: () => onNavigate(i),
                    formatPkr: formatPkr,
                  ),
                ),
              ],
            ),
          ),
        );
    }

    children
      ..add(connectorRow())
      ..add(
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              railColumn(
                children: [
                  flexibleConnector(),
                  circleNode(
                    backgroundColor: ui.brandPrimary,
                    child: Icon(
                      Icons.navigation_rounded,
                      size: 11.sp,
                      color: AppColors.whiteColor,
                    ),
                  ),
                ],
              ),
              10.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      plan.end.name,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    4.verticalSpace,
                    AppText(
                      'Destination • ${targetArrivalBatteryPercent.round()}% battery remaining',
                      color: ui.textMuted,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}


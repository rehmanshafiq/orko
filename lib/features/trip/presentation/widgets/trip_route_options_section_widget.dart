import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_bloc.dart';
import 'package:orko_hubco/features/trip/presentation/models/trip_plan_model.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_route_option_card_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_section_title_widget.dart';

class TripRouteOptionsSectionWidget extends StatelessWidget {
  const TripRouteOptionsSectionWidget({
    required this.routePlans,
    required this.selectedRouteIndex,
    required this.onRouteSelected,
    required this.formatDuration,
    required this.formatPkr,
    super.key,
  });

  final List<TripPlanModel?> routePlans;
  final int selectedRouteIndex;
  final ValueChanged<int> onRouteSelected;
  final String Function(Duration) formatDuration;
  final String Function(int) formatPkr;

  @override
  Widget build(BuildContext context) {
    final fastest = routePlans[0];
    final econ = routePlans[1];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const TripSectionTitleWidget(text: 'Route Options'),
        10.verticalSpace,
        TripRouteOptionCardWidget(
          selected: selectedRouteIndex == 0,
          onTap: () => onRouteSelected(0),
          title: TripPlannerBloc.strategies[0].label,
          subtitle: fastest == null
              ? '—'
              : '${fastest.distanceKm.round()} km • ${formatDuration(fastest.duration)}',
          stops: '${fastest?.stops.length ?? 0}',
          cost: formatPkr(fastest?.costPkr ?? 0),
          co2: '${fastest?.co2SavedKg ?? 0} kg',
          leadingIcon: Icons.show_chart_rounded,
          leadingIconColor: AppColors.whiteColor,
          leadingBgColor: AppColors.ratingStarColor,
        ),
        8.verticalSpace,
        TripRouteOptionCardWidget(
          selected: selectedRouteIndex == 1,
          onTap: () => onRouteSelected(1),
          title: TripPlannerBloc.strategies[1].label,
          subtitle: econ == null
              ? '—'
              : '${econ.distanceKm.round()} km • ${formatDuration(econ.duration)}',
          stops: '${econ?.stops.length ?? 0}',
          cost: formatPkr(econ?.costPkr ?? 0),
          co2: '${econ?.co2SavedKg ?? 0} kg',
          leadingIcon: Icons.attach_money_rounded,
          leadingIconColor: AppColors.primaryDarkColor,
          leadingBgColor: AppColors.primaryLightColor.withValues(alpha: 0.55),
        ),
      ],
    );
  }
}


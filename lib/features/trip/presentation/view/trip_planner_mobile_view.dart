import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_bloc.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_event.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_state.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_battery_sliders_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stops_section_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_ev_details_card_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_header_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_location_field_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_map_card_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_route_options_section_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_route_suggestion_card_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_section_title_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_summary_card_widget.dart';

class TripPlannerMobileView extends StatelessWidget {
  const TripPlannerMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TripPlannerBloc(),
      child: BlocBuilder<TripPlannerBloc, TripPlannerState>(
        builder: (context, state) {
          final bloc = context.read<TripPlannerBloc>();
          final ui = AppUiColors.of(context);

          if (!state.iconsLoaded) {
            context.read<TripPlannerBloc>().add(
                  TripPlannerLoadMarkerIcons(
                    MediaQuery.devicePixelRatioOf(context),
                  ),
                );
          }

          return Scaffold(
            backgroundColor: ui.scaffoldBackground,
            body: SafeArea(
              child: ListView(
                padding: AppUtils.horizontal16Padding,
                children: [
                  10.verticalSpace,
                  const TripHeaderWidget(),
                  16.verticalSpace,
                  TripLocationFieldWidget(
                    controller: bloc.startLocationController,
                    isStart: true,
                  ),
                  8.verticalSpace,
                  TripLocationFieldWidget(
                    controller: bloc.endLocationController,
                    isStart: false,
                  ),
                  14.verticalSpace,
                  const TripSectionTitleWidget(text: 'EV Details'),
                  10.verticalSpace,
                  TripEvDetailsCardWidget(
                    currentBatteryPercent: state.currentBatteryPercent,
                  ),
                  14.verticalSpace,
                  TripBatterySlidersWidget(
                    currentBatteryPercent: state.currentBatteryPercent,
                    targetArrivalBatteryPercent: state.targetArrivalBatteryPercent,
                    kmPerPercentCharge: TripPlannerBloc.kmPerPercentCharge,
                    onCurrentBatteryChanged: (v) =>
                        context.read<TripPlannerBloc>().add(TripPlannerBatteryChanged(v)),
                    onTargetArrivalBatteryChanged: (v) => context
                        .read<TripPlannerBloc>()
                        .add(TripPlannerArrivalBatteryChanged(v)),
                  ),
                  14.verticalSpace,
                  PrimaryButtonWidget(
                    text: 'Plan Trip',
                    onPress: () => context
                        .read<TripPlannerBloc>()
                        .add(const TripPlannerPlanTripPressed()),
                    buttonColor: AppColors.primaryDarkColor,
                    fontWeight: FontWeights.weight700,
                    fontSize: FontSizes.font14Sp,
                    cornerRadius: 8.r,
                  ),
                  if (state.tripPlanned) ...[
                    16.verticalSpace,
                    TripRouteOptionsSectionWidget(
                      routePlans: state.routePlans,
                      selectedRouteIndex: state.selectedRouteIndex,
                      onRouteSelected: (index) => context
                          .read<TripPlannerBloc>()
                          .add(TripPlannerRouteSelected(index)),
                      formatDuration: bloc.formatDuration,
                      formatPkr: bloc.formatPkr,
                    ),
                    12.verticalSpace,
                    TripMapCardWidget(
                      plan: state.currentPlan,
                      startIcon: state.startIcon,
                      endIcon: state.endIcon,
                      stopIcon: state.stopIcon,
                      darkMapStyle: TripPlannerBloc.darkMapStyle,
                      onMapCreated: (controller) => context
                          .read<TripPlannerBloc>()
                          .add(TripPlannerMapCreated(controller)),
                    ),
                    16.verticalSpace,
                    TripChargingStopsSectionWidget(
                      plan: state.currentPlan,
                      currentBatteryPercent: state.currentBatteryPercent,
                      targetArrivalBatteryPercent: state.targetArrivalBatteryPercent,
                      expandedChargingStopIndex: state.expandedChargingStopIndex,
                      onToggleChargingStop: (index) => context
                          .read<TripPlannerBloc>()
                          .add(TripPlannerChargingStopExpanded(index)),
                      onViewDetails: (index) => bloc.openChargingStationDetails(
                        context,
                        station: state.currentPlan!.stops[index],
                      ),
                      onPreBook: () => bloc.openPreBook(context),
                      formatPkr: bloc.formatPkr,
                    ),
                    16.verticalSpace,
                    TripRouteSuggestionCardWidget(
                      fastestPlan: state.routePlans[0],
                      economicalPlan: state.routePlans[1],
                    ),
                    22.verticalSpace,
                    const TripSectionTitleWidget(text: 'Trip Summary'),
                    8.verticalSpace,
                    TripSummaryCardWidget(
                      plan: state.currentPlan,
                      formatDuration: bloc.formatDuration,
                      formatPkr: bloc.formatPkr,
                    ),
                    22.verticalSpace,
                  ],
                  24.verticalSpace,
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


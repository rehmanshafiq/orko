import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_functions.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/presentation/booked_stations_session.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_bloc.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_event.dart';
import 'package:orko_hubco/features/trip/presentation/bloc/trip_planner_state.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stops_section_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_current_battery_slider_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_ev_details_card_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_header_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/place_search_sheet.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_location_field_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/phev_notice_dialog.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_map_card_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_section_title_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_summary_card_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_vehicle_dropdown_widget.dart';
import 'package:orko_hubco/features/trip/presentation/view/saved_trips_view.dart';

class TripPlannerMobileView extends StatefulWidget {
  const TripPlannerMobileView({super.key, this.editTrip});

  /// When non-null, the planner opens in edit mode: fields, vehicle and start
  /// SoC are pre-filled from this saved trip, and the primary save action
  /// becomes "Edit Trip" (calls the edit-trip API) once the user re-plans.
  final SavedTripEntity? editTrip;

  @override
  State<TripPlannerMobileView> createState() => _TripPlannerMobileViewState();
}

class _TripPlannerMobileViewState extends State<TripPlannerMobileView> {
  /// Bumped by "Clear" so the vehicle (Make) dropdown — which keeps its own
  /// selection state — is rebuilt fresh alongside the bloc reset.
  int _formResetTick = 0;

  final ScrollController _scrollController = ScrollController();

  /// Anchors the Suggested Stops section so a successful plan can scroll to it.
  final GlobalKey _suggestedStopsKey = GlobalKey();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Seed the vehicle dropdown so it opens showing the saved trip's vehicle
    // (the bloc's selectedVehicle drives the EV card; this drives the field).
    if (widget.editTrip != null) {
      TripVehicleDropdownWidget.setSavedSelection(widget.editTrip!.vehicle);
    }
  }

  /// Resets the planned trip + form and forces the Make dropdown to clear.
  /// Also drops the session's "Booked" stop marks so a fresh plan starts clean.
  void _onClear(BuildContext context) {
    TripVehicleDropdownWidget.clearSavedSelection();
    BookedStationsSession.clear();
    context.read<TripPlannerBloc>().add(const TripPlannerResetRequested());
    setState(() => _formResetTick++);
  }

  /// Runs guest + form validation, then dispatches the plan-trip request.
  ///
  /// PHEV (Plug-in Hybrid) vehicles first get an informational popup — shown on
  /// every Plan Trip tap — because the plan only accounts for electric range;
  /// planning proceeds only if the user chooses to continue.
  Future<void> _onPlanTrip(
    BuildContext context,
    TripPlannerBloc bloc,
    TripPlannerState state,
  ) async {
    // Already in flight — ignore repeat taps.
    if (state.planLoading) return;

    // Guests can browse but must authenticate before planning a trip.
    if (AppStorage.isGuest) {
      AuthRequiredDialog.show(
        context,
        feature: 'trip',
        message:
            'You\'re browsing as a guest. Please log in or create an account to plan a trip.',
      );
      return;
    }

    final error = _validateTrip(bloc, state);
    if (error != null) {
      _showValidationError(context, error);
      return;
    }

    // PHEV notice — validation above guarantees a selected vehicle here.
    if (state.selectedVehicle?.isPhev ?? false) {
      final proceed = await PhevNoticeDialog.show(context);
      if (!proceed || !context.mounted) return;
    }

    FocusScope.of(context).unfocus();
    context.read<TripPlannerBloc>().add(const TripPlannerPlanTripRequested());
  }

  /// Returns the first validation error message, or null when the form is
  /// ready to plan. Covers empty/duplicate locations, missing or incomplete
  /// vehicle data, and an invalid battery level.
  String? _validateTrip(TripPlannerBloc bloc, TripPlannerState state) {
    final start = bloc.startLocationController.text.trim();
    final end = bloc.endLocationController.text.trim();

    if (start.isEmpty) {
      return 'Please choose your start location.';
    }
    if (end.isEmpty) {
      return 'Please choose your destination.';
    }
    if (start.toLowerCase() == end.toLowerCase()) {
      return 'Start and destination can\'t be the same place.';
    }

    final vehicle = state.selectedVehicle;
    if (vehicle == null) {
      return 'Please select a vehicle for this trip.';
    }
    if (vehicle.range == null ||
        vehicle.range == 0 ||
        vehicle.batteryCapacity == null) {
      return 'Selected vehicle is missing battery/range details. Pick another vehicle.';
    }

    final battery = state.currentBatteryPercent;
    if (battery <= 0) {
      return 'Set your current battery level above 0% to plan a trip.';
    }

    return null;
  }

  /// Launches Google Maps with the planned journey as a single route:
  /// start → every suggested charging stop (in sequence, by lat/lng) →
  /// destination, so the user can start navigating the whole trip.
  Future<void> _onStartJourney(
    BuildContext context,
    TripPlannerState state,
  ) async {
    final plan = state.currentPlan;
    if (plan == null) return;
    try {
      await AppFunctions.openGoogleMapsJourney(
        originLatitude: plan.start.latitude,
        originLongitude: plan.start.longitude,
        destinationLatitude: plan.end.latitude,
        destinationLongitude: plan.end.longitude,
        stops: plan.stops
            .map((s) => (latitude: s.latitude, longitude: s.longitude))
            .toList(),
      );
    } catch (_) {
      if (context.mounted) {
        _showValidationError(
          context,
          'Could not open Google Maps. Please make sure it is installed.',
        );
      }
    }
  }

  /// Opens the user's preferred maps app with directions to the suggested
  /// charging stop at [index] (by the station's lat/lng).
  Future<void> _onNavigateToStop(
    BuildContext context,
    TripPlannerState state,
    int index,
  ) async {
    final stops = state.currentPlan?.stops;
    if (stops == null || index >= stops.length) return;
    final station = stops[index];
    try {
      await AppFunctions.openPreferredMapsDirections(
        latitude: station.latitude,
        longitude: station.longitude,
        label: station.name,
      );
    } catch (_) {
      if (context.mounted) {
        _showValidationError(
          context,
          'Could not open a maps app for directions.',
        );
      }
    }
  }

  /// After a successful plan, scrolls down to the Suggested Stops section
  /// (or to the bottom of the results when the plan has no charging stops).
  void _scrollToSuggestedStops() {
    // Wait for the frame that lays out the freshly-built results first.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !_scrollController.hasClients) return;

      var stopsContext = _suggestedStopsKey.currentContext;
      if (stopsContext == null) {
        // The ListView builds children lazily, so the section may not exist
        // yet — scroll to the end to force it into the tree, then align it.
        await _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
        if (!mounted) return;
        stopsContext = _suggestedStopsKey.currentContext;
      }
      if (stopsContext != null && stopsContext.mounted) {
        await Scrollable.ensureVisible(
          stopsContext,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  /// Surfaces a validation message as a floating snackbar.
  void _showValidationError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.removeColor,
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  /// Opens the Google Places search sheet and stores the picked place on the
  /// bloc so trip planning uses its exact coordinates.
  Future<void> _pickLocation(
    BuildContext context,
    TripPlannerBloc bloc, {
    required bool isStart,
  }) async {
    final place = await showPlaceSearchSheet(
      context,
      title: isStart ? 'Start location' : 'Destination',
      // "Use my current location" is offered only for the start field.
      showCurrentLocation: isStart,
    );
    if (place == null) return;
    if (isStart) {
      bloc.selectStartPlace(
        name: place.name,
        lat: place.latitude,
        lng: place.longitude,
      );
    } else {
      bloc.selectEndPlace(
        name: place.name,
        lat: place.latitude,
        lng: place.longitude,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TripPlannerBloc(editingTrip: widget.editTrip),
      child: BlocListener<TripPlannerBloc, TripPlannerState>(
        // The plan request just finished successfully — take the user to the
        // suggested charging stops.
        listenWhen: (p, c) =>
            p.planLoading &&
            !c.planLoading &&
            c.tripPlanned &&
            c.planError == null,
        listener: (context, state) => _scrollToSuggestedStops(),
        child: BlocConsumer<TripPlannerBloc, TripPlannerState>(
          listenWhen: (p, c) =>
              p.saveSuccess != c.saveSuccess || p.saveError != c.saveError,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            if (state.saveSuccess) {
              if (state.isEditMode) {
                // Edit succeeded — toast and return to the trip detail (true tells
                // it to reload the freshly-recomputed trip).
                Fluttertoast.showToast(
                  msg: 'Trip plan updated successfully.',
                  toastLength: Toast.LENGTH_SHORT,
                  gravity: ToastGravity.BOTTOM,
                );
                Navigator.of(context).pop(true);
                return;
              }
              messenger.showSnackBar(
                const SnackBar(
                  content: Text('Trip plan saved successfully.'),
                  backgroundColor: AppColors.primaryDarkColor,
                ),
              );
            } else if (state.saveError != null) {
              messenger.showSnackBar(
                SnackBar(
                  content: Text(state.saveError!),
                  backgroundColor: AppColors.removeColor,
                ),
              );
            }
          },
          builder: (context, state) {
            final bloc = context.read<TripPlannerBloc>();
            final ui = AppUiColors.of(context);

            // No enroute chargers were found (or the trip is infeasible with the
            // available ones) — hide the Suggested Stops and Trip Summary sections.
            final hasStops = state.currentPlan?.stops.isNotEmpty ?? false;

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
                  controller: _scrollController,
                  padding: AppUtils.horizontal16Padding,
                  children: [
                    10.verticalSpace,
                    Row(
                      children: [
                        // Edit mode is pushed as a route (no AppBar) — give it a
                        // back affordance.
                        if (widget.editTrip != null) ...[
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => Navigator.of(context).maybePop(),
                            child: Icon(
                              Icons.arrow_back_rounded,
                              color: ui.textPrimary,
                              size: 22.sp,
                            ),
                          ),
                          8.horizontalSpace,
                        ],
                        const Expanded(child: TripHeaderWidget()),
                        // "Clear" appears once a trip is planned or every field is
                        // filled. Listens to the location controllers so it toggles
                        // as they change (those don't emit bloc state on their own).
                        ListenableBuilder(
                          listenable: Listenable.merge([
                            bloc.startLocationController,
                            bloc.endLocationController,
                          ]),
                          builder: (context, _) {
                            final allFieldsFilled = bloc
                                    .startLocationController.text
                                    .trim()
                                    .isNotEmpty &&
                                bloc.endLocationController.text
                                    .trim()
                                    .isNotEmpty &&
                                state.selectedVehicle != null;
                            if (!state.tripPlanned && !allFieldsFilled) {
                              return const SizedBox.shrink();
                            }
                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _onClear(context),
                                  child: AppText(
                                    'Clear',
                                    color: AppColors.removeColor,
                                    fontSize: FontSizes.font12Sp,
                                    fontWeight: FontWeights.weight700,
                                  ),
                                ),
                                16.horizontalSpace,
                              ],
                            );
                          },
                        ),
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (AppStorage.isGuest) {
                              AuthRequiredDialog.show(
                                context,
                                feature: 'trip',
                                message:
                                    'Please log in or create an account to view your saved trips.',
                              );
                              return;
                            }
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const SavedTripsView(),
                              ),
                            );
                          },
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.bookmark_border_rounded,
                                size: 18.sp,
                                color: ui.brandPrimary,
                              ),
                              4.horizontalSpace,
                              AppText(
                                'Saved',
                                color: ui.brandPrimary,
                                fontSize: FontSizes.font12Sp,
                                fontWeight: FontWeights.weight700,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    16.verticalSpace,
                    TripLocationFieldWidget(
                      controller: bloc.startLocationController,
                      isStart: true,
                      onTap: () => _pickLocation(context, bloc, isStart: true),
                    ),
                    8.verticalSpace,
                    TripLocationFieldWidget(
                      controller: bloc.endLocationController,
                      isStart: false,
                      onTap: () => _pickLocation(context, bloc, isStart: false),
                    ),
                    12.verticalSpace,
                    TripVehicleDropdownWidget(
                      key: ValueKey<int>(_formResetTick),
                      // Edit mode: resolve the complete vehicle (battery/range)
                      // from the user-vehicle API by id, not the trip's slim copy.
                      initialVehicleId: widget.editTrip?.vehicle?.id,
                      onVehicleSelected: (vehicle) => context
                          .read<TripPlannerBloc>()
                          .add(TripPlannerVehicleSelected(vehicle)),
                    ),
                    14.verticalSpace,
                    const TripSectionTitleWidget(text: 'EV Details'),
                    10.verticalSpace,
                    TripEvDetailsCardWidget(
                      currentBatteryPercent: state.currentBatteryPercent,
                      vehicle: state.selectedVehicle,
                    ),
                    14.verticalSpace,
                    // TripBatterySlidersWidget(
                    //   currentBatteryPercent: state.currentBatteryPercent,
                    //   targetArrivalBatteryPercent: state.targetArrivalBatteryPercent,
                    //   kmPerPercentCharge: TripPlannerBloc.kmPerPercentCharge,
                    //   onCurrentBatteryChanged: (v) =>
                    //       context.read<TripPlannerBloc>().add(TripPlannerBatteryChanged(v)),
                    //   onTargetArrivalBatteryChanged: (v) => context
                    //       .read<TripPlannerBloc>()
                    //       .add(TripPlannerArrivalBatteryChanged(v)),
                    // ),
                    // 14.verticalSpace,
                    TripCurrentBatterySliderWidget(
                      currentBatteryPercent: state.currentBatteryPercent,
                      onChanged: (v) => context
                          .read<TripPlannerBloc>()
                          .add(TripPlannerBatteryChanged(v)),
                    ),
                    16.verticalSpace,
                    // PrimaryButtonWidget(
                    //   text: 'Plan Trip',
                    //   onPress: () => context
                    //       .read<TripPlannerBloc>()
                    //       .add(const TripPlannerPlanTripPressed()),
                    //   buttonColor: ui.brandPrimary,
                    //   textColor: AppColors.whiteColor,
                    //   fontWeight: FontWeights.weight700,
                    //   fontSize: FontSizes.font14Sp,
                    //   cornerRadius: 24.r,
                    // ),

                    12.verticalSpace,
                    PrimaryButtonWidget(
                      text: state.planLoading ? 'Planning…' : 'Plan Trip',
                      isEnabled: !state.planLoading,
                      onPress: () => _onPlanTrip(context, bloc, state),
                      gradientColors: const [
                        AppColors.primaryDarkColor,
                        AppColors.primaryDarkButtonColor,
                      ],
                      textColor: AppColors.whiteColor,
                      fontWeight: FontWeights.weight700,
                      fontSize: FontSizes.font14Sp,
                      cornerRadius: 24.r,
                    ),
                    if (state.planError != null && !state.planLoading) ...[
                      12.verticalSpace,
                      _TripBanner(
                        color: AppColors.redColor,
                        icon: Icons.error_outline_rounded,
                        text: state.planError!,
                      ),
                    ],
                    // 12.verticalSpace,
                    // PrimaryButtonWidget(
                    //   text: 'Plan Trip',
                    //   onPress: () => context
                    //       .read<TripPlannerBloc>()
                    //       .add(const TripPlannerPlanTripPressed()),
                    //   gradientColors: const [
                    //     Color(0xFF14845E),
                    //     Color(0xFF0E6749),
                    //     Color(0xFF094C3A),
                    //   ],
                    //   textColor: AppColors.whiteColor,
                    //   fontWeight: FontWeights.weight700,
                    //   fontSize: FontSizes.font14Sp,
                    //   cornerRadius: 24.r,
                    // ),
                    12.verticalSpace,
                    // PrimaryButtonWidget(
                    //   text: 'Plan Trip',
                    //   onPress: () => context
                    //       .read<TripPlannerBloc>()
                    //       .add(const TripPlannerPlanTripPressed()),
                    //   gradientColors: const [
                    //     AppColors.primaryDarkColor,
                    //     AppColors.primaryDarkColor,
                    //   ],
                    //   textColor: AppColors.whiteColor,
                    //   fontWeight: FontWeights.weight700,
                    //   fontSize: FontSizes.font14Sp,
                    //   cornerRadius: 24.r,
                    // ),
                    // // SilverMetallicButtonWidget(
                    // //   text: 'Plan Trip',
                    // //   onPress: () => context
                    // //       .read<TripPlannerBloc>()
                    // //       .add(const TripPlannerPlanTripPressed()),
                    // //   cornerRadius: 24.r,
                    // // ),
                    // 12.verticalSpace,
                    // PrimaryButtonWidget(
                    //   text: 'Plan Trip',
                    //   onPress: () => context
                    //       .read<TripPlannerBloc>()
                    //       .add(const TripPlannerPlanTripPressed()),
                    //   gradientColors: const [
                    //     Color(0xFF00C060),
                    //     Color(0xFF010203),
                    //   ],
                    //   textColor: AppColors.whiteColor,
                    //   fontWeight: FontWeights.weight700,
                    //   fontSize: FontSizes.font14Sp,
                    //   cornerRadius: 24.r,
                    // ),
                    // 12.verticalSpace,
                    // PrimaryButtonWidget(
                    //   text: 'Plan Trip',
                    //   onPress: () => context
                    //       .read<TripPlannerBloc>()
                    //       .add(const TripPlannerPlanTripPressed()),
                    //   gradientColors: const [
                    //     Color(0xFF014122),
                    //     Color(0xFF010203),
                    //   ],
                    //   textColor: AppColors.whiteColor,
                    //   fontWeight: FontWeights.weight700,
                    //   fontSize: FontSizes.font14Sp,
                    //   cornerRadius: 24.r,
                    // ),
                    if (state.tripPlanned) ...[
                      16.verticalSpace,
                      if (state.feasible == false) ...[
                        _TripBanner(
                          color: AppColors.ratingStarColor,
                          icon: Icons.warning_amber_rounded,
                          text: state.apiPlan?.message ??
                              'This trip cannot be completed with the available enroute chargers. Showing the partial route reached.',
                        ),
                        16.verticalSpace,
                      ],
                      // Route map above the stops list.
                      TripMapCardWidget(
                        plan: state.currentPlan,
                        startIcon: state.startIcon,
                        endIcon: state.endIcon,
                        stopIcon: state.stopIcon,
                        darkMapStyle: TripPlannerBloc.darkMapStyle,
                        onMapCreated: (controller) => context
                            .read<TripPlannerBloc>()
                            .add(TripPlannerMapCreated(controller)),
                        onStopTap: (index) => bloc.openChargingStationDetails(
                          context,
                          station: state.currentPlan!.stops[index],
                        ),
                      ),
                      // Suggested Stops + Trip Summary only make sense when the
                      // plan actually has charging stops along the route.
                      if (hasStops) ...[
                        16.verticalSpace,
                        // Rebuilds when a booking succeeds anywhere in the session
                        // so already-booked stops show "Booked" on return here.
                        ValueListenableBuilder<Set<int>>(
                          key: _suggestedStopsKey,
                          valueListenable: BookedStationsSession.ids,
                          builder: (context, bookedIds, _) =>
                              TripChargingStopsSectionWidget(
                            plan: state.currentPlan,
                            currentBatteryPercent: state.currentBatteryPercent,
                            targetArrivalBatteryPercent:
                                state.targetArrivalBatteryPercent,
                            expandedChargingStopIndex:
                                state.expandedChargingStopIndex,
                            bookedStationIds: bookedIds,
                            onToggleChargingStop: (index) => context
                                .read<TripPlannerBloc>()
                                .add(TripPlannerChargingStopExpanded(index)),
                            onViewDetails: (index) =>
                                bloc.openChargingStationDetails(
                              context,
                              station: state.currentPlan!.stops[index],
                            ),
                            onPreBook: (index) => bloc.openPreBook(
                              context,
                              station: state.currentPlan!.stops[index],
                              stopIndex: index,
                            ),
                            onNavigate: (index) =>
                                _onNavigateToStop(context, state, index),
                            formatPkr: bloc.formatPkr,
                          ),
                        ),
                        16.verticalSpace,
                        const TripSectionTitleWidget(text: 'Trip Summary'),
                        8.verticalSpace,
                        TripSummaryCardWidget(
                          plan: state.currentPlan,
                          formatDuration: bloc.formatDuration,
                          formatPkr: bloc.formatPkr,
                        ),
                      ],
                      16.verticalSpace,
                      // Outlined style matches Start Journey below (no icon).
                      SizedBox(
                        height: 38.h,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: state.saving
                              ? null
                              : () {
                                  if (state.isEditMode) {
                                    // Edited an input after planning → the shown
                                    // plan is stale; make them re-plan first.
                                    if (bloc.hasUnplannedChanges) {
                                      _showValidationError(
                                        context,
                                        'You\'ve changed the trip details. Tap Plan Trip again before updating.',
                                      );
                                      return;
                                    }
                                    // Nothing changed vs the saved trip → block a
                                    // no-op update.
                                    if (!bloc.editHasChanges) {
                                      _showValidationError(
                                        context,
                                        'Change the start, destination, vehicle or battery before updating your trip.',
                                      );
                                      return;
                                    }
                                  }
                                  context.read<TripPlannerBloc>().add(
                                        state.isEditMode
                                            ? const TripPlannerEditTripRequested()
                                            : const TripPlannerSaveTripRequested(),
                                      );
                                },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ui.textPrimary,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.r),
                            ),
                          ).copyWith(
                            // Click feedback: the outline turns brand-primary
                            // while the button is pressed.
                            side: WidgetStateProperty.resolveWith(
                              (states) => BorderSide(
                                color: states.contains(WidgetState.pressed)
                                    ? ui.brandPrimary
                                    : ui.textPrimary.withValues(
                                        alpha: state.saving ? 0.35 : 0.85,
                                      ),
                              ),
                            ),
                          ),
                          child: AppText(
                            state.isEditMode
                                ? (state.saving ? 'Updating…' : 'Edit Trip')
                                : (state.saving ? 'Saving…' : 'Save Trip'),
                            color: ui.textPrimary,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight600,
                          ),
                        ),
                      ),
                      12.verticalSpace,
                      // Opens Google Maps with the whole trip as one journey —
                      // every suggested stop mapped as a waypoint on the route.
                      // Outlined style matches the Directions button on the
                      // charging station detail screen.
                      SizedBox(
                        height: 38.h,
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => _onStartJourney(context, state),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: ui.textPrimary,
                            padding: EdgeInsets.symmetric(horizontal: 12.w),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(32.r),
                            ),
                          ).copyWith(
                            // Click feedback: the outline turns brand-primary
                            // while the button is pressed.
                            side: WidgetStateProperty.resolveWith(
                              (states) => BorderSide(
                                color: states.contains(WidgetState.pressed)
                                    ? ui.brandPrimary
                                    : ui.textPrimary.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.navigation_rounded, size: 18.r),
                              8.horizontalSpace,
                              AppText(
                                'Start Journey',
                                color: ui.textPrimary,
                                fontSize: FontSizes.font14Sp,
                                fontWeight: FontWeights.weight600,
                              ),
                            ],
                          ),
                        ),
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
      ),
    );
  }
}

/// Inline status banner for plan errors (red) and the feasible:false warning.
class _TripBanner extends StatelessWidget {
  const _TripBanner({
    required this.color,
    required this.icon,
    required this.text,
  });

  final Color color;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: color),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18.sp),
          8.horizontalSpace,
          Expanded(
            child: AppText(
              text,
              color: color,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
        ],
      ),
    );
  }
}

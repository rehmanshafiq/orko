import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_plan_entity.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_stop_entity.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_amenity_chip_widget.dart';
import 'package:orko_hubco/features/trip/presentation/widgets/trip_charging_stop_metric_widget.dart';

/// "All Stops" tab body: every charger along the planned route (the API's
/// `all_stations` browse mode). Cards mirror the Recommended stop cards
/// (same container, expand/collapse accordion) but — since no charging is
/// simulated in this mode — omit SoC / cost / charging-time.
class TripAllStopsSectionWidget extends StatefulWidget {
  const TripAllStopsSectionWidget({
    required this.loading,
    required this.error,
    required this.plan,
    required this.onRetry,
    required this.onViewDetails,
    required this.onPreBook,
    required this.onNavigate,
    this.bookedStationIds = const <int>{},
    super.key,
  });

  /// True while the browse list is being fetched.
  final bool loading;

  /// Fetch error, if any.
  final String? error;

  /// The loaded browse result; null before the first successful fetch.
  final TripPlanEntity? plan;

  final VoidCallback onRetry;

  /// All three are indexed into [plan]'s stops (kept in sync with the list).
  final ValueChanged<int> onViewDetails;
  final ValueChanged<int> onPreBook;
  final ValueChanged<int> onNavigate;

  /// Station ids booked this session — their cards read "Booked".
  final Set<int> bookedStationIds;

  @override
  State<TripAllStopsSectionWidget> createState() =>
      _TripAllStopsSectionWidgetState();
}

class _TripAllStopsSectionWidgetState extends State<TripAllStopsSectionWidget> {
  /// Index of the currently-expanded card (accordion — one at a time), or null
  /// when all are collapsed. Mirrors the Recommended list's expand behaviour.
  int? _expandedIndex;

  @override
  void didUpdateWidget(covariant TripAllStopsSectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A fresh browse result invalidates the expanded index.
    if (oldWidget.plan != widget.plan) _expandedIndex = null;
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    if (widget.loading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 40.h),
        child: Center(
          child: SizedBox(
            width: 26.w,
            height: 26.w,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: ui.brandPrimary,
            ),
          ),
        ),
      );
    }

    if (widget.error != null) {
      return _AllStopsMessage(
        ui: ui,
        icon: Icons.error_outline_rounded,
        title: 'Couldn\'t load stations',
        subtitle: widget.error!,
        action: SizedBox(
          width: 160.w,
          child: PrimaryButtonWidget(
            text: 'Retry',
            onPress: widget.onRetry,
            buttonHeight: 40.h,
            cornerRadius: 22.r,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
      );
    }

    final stops = widget.plan?.stops ?? const <TripStopEntity>[];
    if (widget.plan == null || stops.isEmpty) {
      return _AllStopsMessage(
        ui: ui,
        icon: Icons.ev_station_outlined,
        title: 'No stations found',
        subtitle: "We couldn't find any charging stations along this route yet.",
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppText(
          _summaryLine(stops.length, widget.plan!.totalDistanceKm),
          color: ui.textMuted,
          fontSize: FontSizes.font10Sp,
          fontWeight: FontWeights.weight400,
        ),
        12.verticalSpace,
        for (var i = 0; i < stops.length; i++) ...[
          if (i > 0) 8.verticalSpace,
          _AllStopCard(
            ui: ui,
            stop: stops[i],
            booked: widget.bookedStationIds.contains(stops[i].locationId),
            expanded: _expandedIndex == i,
            onToggleExpanded: () => setState(
              () => _expandedIndex = _expandedIndex == i ? null : i,
            ),
            onViewDetails: () => widget.onViewDetails(i),
            onPreBook: () => widget.onPreBook(i),
            onNavigate: () => widget.onNavigate(i),
          ),
        ],
      ],
    );
  }

  /// "N stations along your route · 403 km".
  String _summaryLine(int count, double distanceKm) {
    final stationsLabel = '$count station${count == 1 ? '' : 's'} along your route';
    if (distanceKm <= 0) return stationsLabel;
    return '$stationsLabel · ${distanceKm.toStringAsFixed(0)} km';
  }
}

/// Centered icon + message block reused for the loading-error and empty states.
class _AllStopsMessage extends StatelessWidget {
  const _AllStopsMessage({
    required this.ui,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.action,
  });

  final AppUiColors ui;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ui.textSecondary, size: 34.sp),
          14.verticalSpace,
          AppText(
            title,
            textAlign: TextAlign.center,
            color: ui.textPrimary,
            fontSize: FontSizes.font16Sp,
            fontWeight: FontWeights.weight700,
          ),
          6.verticalSpace,
          AppText(
            subtitle,
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          if (action != null) ...[
            16.verticalSpace,
            action!,
          ],
        ],
      ),
    );
  }
}

/// A single browse-mode station card, styled and expanded like the Recommended
/// stop card: header + connector + previous-stop distance always visible;
/// amenities and the View Details / Pre-book / Navigate actions revealed on
/// expand.
class _AllStopCard extends StatelessWidget {
  const _AllStopCard({
    required this.ui,
    required this.stop,
    required this.booked,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onViewDetails,
    required this.onPreBook,
    required this.onNavigate,
  });

  final AppUiColors ui;
  final TripStopEntity stop;

  /// Booked this session — the Pre-book button reads "Booked" and is disabled.
  final bool booked;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onViewDetails;
  final VoidCallback onPreBook;
  final VoidCallback onNavigate;

  /// A station with no usable connector still appears in this mode; the API
  /// signals it with a null connector id.
  bool get _hasUsableConnector =>
      stop.connectorId != null && stop.connectorType.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
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
                      stop.locationName.isEmpty
                          ? 'Charging station'
                          : stop.locationName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    if ((stop.locationAddress ?? '').trim().isNotEmpty) ...[
                      4.verticalSpace,
                      AppText(
                        stop.locationAddress!.trim(),
                        color: ui.textMuted,
                        fontSize: FontSizes.font10Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ],
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
                    expanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    size: 22.sp,
                    color: ui.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          12.verticalSpace,
          _ConnectorLine(
            ui: ui,
            hasUsableConnector: _hasUsableConnector,
            connectorType: stop.connectorType,
            connectorPowerKw: stop.connectorPowerKw,
            matchesVehicle: stop.connectorTypeMatchesVehicle,
          ),
          if ((stop.distanceFromPreviousStopKm ?? 0) > 0) ...[
            10.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: TripChargingStopMetricWidget(
                    label: 'Distance from previous stop',
                    value:
                        '${stop.distanceFromPreviousStopKm!.toStringAsFixed(2)} km',
                    valueColor: ui.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          if (expanded) ...[
            if (stop.amenities.isNotEmpty) ...[
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
                    for (var i = 0; i < stop.amenities.length; i++) ...[
                      if (i > 0) 8.horizontalSpace,
                      TripChargingAmenityChipWidget(
                        icon: _amenityIcon(stop.amenities[i]),
                        label: stop.amenities[i],
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
                    // Disabled once booked, matching the Recommended card.
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
                    // Can't pre-book a station with no usable connector, or one
                    // already booked this session.
                    isEnabled: !booked && _hasUsableConnector,
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

  IconData _amenityIcon(String amenity) {
    final key = amenity.toLowerCase().trim();
    if (key.contains('wifi') || key.contains('wi-fi')) {
      return Icons.wifi_rounded;
    }
    if (key.contains('air') || key.contains('ac') || key.contains('a/c')) {
      return Icons.ac_unit_rounded;
    }
    if (key.contains('restroom') || key.contains('toilet') || key.contains('washroom')) {
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
}

class _ConnectorLine extends StatelessWidget {
  const _ConnectorLine({
    required this.ui,
    required this.hasUsableConnector,
    required this.connectorType,
    required this.connectorPowerKw,
    required this.matchesVehicle,
  });

  final AppUiColors ui;
  final bool hasUsableConnector;
  final String connectorType;
  final double connectorPowerKw;
  final bool matchesVehicle;

  @override
  Widget build(BuildContext context) {
    if (!hasUsableConnector) {
      return Row(
        children: [
          Icon(
            Icons.power_off_outlined,
            size: 14.sp,
            color: AppColors.ratingStarColor,
          ),
          6.horizontalSpace,
          Expanded(
            child: AppText(
              'No usable connector at this station',
              color: AppColors.ratingStarColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
        ],
      );
    }

    final power = connectorPowerKw > 0 ? ' · ${connectorPowerKw.toStringAsFixed(0)} kW' : '';
    return Row(
      children: [
        Icon(Icons.ev_station_rounded, size: 14.sp, color: ui.brandPrimary),
        6.horizontalSpace,
        Expanded(
          child: AppText(
            '$connectorType$power',
            color: ui.textPrimary,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight500,
          ),
        ),
        if (!matchesVehicle) ...[
          6.horizontalSpace,
          AppText(
            'May not fit your vehicle',
            color: AppColors.ratingStarColor,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight600,
          ),
        ],
      ],
    );
  }
}

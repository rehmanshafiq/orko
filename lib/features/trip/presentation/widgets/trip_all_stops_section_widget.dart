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
/// `all_stations` browse mode). No charging is simulated in this mode, so the
/// cards deliberately omit SoC / cost / charging-time and show only station
/// identity, distance and connector availability.
class TripAllStopsSectionWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    if (loading) {
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

    if (error != null) {
      return _AllStopsMessage(
        ui: ui,
        icon: Icons.error_outline_rounded,
        title: 'Couldn\'t load stations',
        subtitle: error!,
        action: SizedBox(
          width: 160.w,
          child: PrimaryButtonWidget(
            text: 'Retry',
            onPress: onRetry,
            buttonHeight: 40.h,
            cornerRadius: 22.r,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
      );
    }

    final stops = plan?.stops ?? const <TripStopEntity>[];
    if (plan == null || stops.isEmpty) {
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
          _summaryLine(stops.length, plan!.totalDistanceKm),
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
            booked: bookedStationIds.contains(stops[i].locationId),
            onViewDetails: () => onViewDetails(i),
            onPreBook: () => onPreBook(i),
            onNavigate: () => onNavigate(i),
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

/// A single browse-mode station card: identity, distance-from-start, connector
/// availability, amenities, and View Details / Navigate actions.
class _AllStopCard extends StatelessWidget {
  const _AllStopCard({
    required this.ui,
    required this.stop,
    required this.booked,
    required this.onViewDetails,
    required this.onPreBook,
    required this.onNavigate,
  });

  final AppUiColors ui;
  final TripStopEntity stop;

  /// Booked this session — the Pre-book button reads "Booked" and is disabled.
  final bool booked;
  final VoidCallback onViewDetails;
  final VoidCallback onPreBook;
  final VoidCallback onNavigate;

  /// A station with no usable connector still appears in this mode; the API
  /// signals it with a null connector id.
  bool get _hasUsableConnector => stop.connectorId != null && stop.connectorType.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUtils.vertical10Horizontal12Padding,
      decoration: BoxDecoration(
        color: ui.searchBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.borderSubtle),
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
                      stop.locationName.isEmpty ? 'Charging station' : stop.locationName,
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
              // Hide the distance chip entirely when the API gives no value.
              if (stop.distanceFromStartKm > 0) ...[
                8.horizontalSpace,
                _DistanceBadge(ui: ui, km: stop.distanceFromStartKm),
              ],
            ],
          ),
          10.verticalSpace,
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
                    value: '${stop.distanceFromPreviousStopKm!.toStringAsFixed(2)} km',
                    valueColor: ui.textPrimary,
                  ),
                ),
              ],
            ),
          ],
          if (stop.amenities.isNotEmpty) ...[
            10.verticalSpace,
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
          12.verticalSpace,
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

class _DistanceBadge extends StatelessWidget {
  const _DistanceBadge({required this.ui, required this.km});

  final AppUiColors ui;
  final double km;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: ui.vehicleStatBoxBg,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: AppText(
        '${km.toStringAsFixed(0)} km',
        color: ui.textSecondary,
        fontSize: FontSizes.font10Sp,
        fontWeight: FontWeights.weight600,
      ),
    );
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

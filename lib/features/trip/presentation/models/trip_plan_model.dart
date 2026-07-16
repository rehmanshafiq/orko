import 'package:orko_hubco/core/constants/charging_stations.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/trip/presentation/models/latlng_named_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/route_strategy_model.dart';
import 'package:orko_hubco/features/trip/presentation/models/stop_charge_info_model.dart';

class TripPlanModel {
  const TripPlanModel({
    required this.strategy,
    required this.start,
    required this.end,
    required this.stops,
    required this.waypoints,
    required this.chargeInfo,
    required this.distanceKm,
    required this.duration,
    required this.costPkr,
    required this.co2SavedKg,
    this.petrolCostSavings,
    this.co2ReducedKg,
  });

  final RouteStrategyModel strategy;
  final GeoPoint start;
  final GeoPoint end;
  final List<HubcoLocationEntity> stops;
  final List<LatLngNamedModel> waypoints;
  final List<StopChargeInfoModel> chargeInfo;
  final double distanceKm;
  final Duration duration;
  final int costPkr;
  final int co2SavedKg;

  /// Fuel-cost savings (plan currency) vs an equivalent petrol trip; null when
  /// the API omits the `savings` object (e.g. the mock recompute path).
  final double? petrolCostSavings;

  /// CO₂ (kg) avoided by driving electric; null when unavailable.
  final double? co2ReducedKg;
}


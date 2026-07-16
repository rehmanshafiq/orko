import 'package:orko_hubco/features/trip/data/models/trip_json.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_savings_entity.dart';

/// Maps the `savings` object of `POST /trip-planning/plan-trip/`.
class TripSavingsModel extends TripSavingsEntity {
  const TripSavingsModel({
    required super.petrolLiters,
    required super.petrolPricePerLiter,
    required super.petrolCost,
    required super.petrolCostSavings,
    required super.co2ReducedKg,
  });

  factory TripSavingsModel.fromJson(Map<String, dynamic> json) {
    return TripSavingsModel(
      petrolLiters: TripJson.asDouble(json['petrol_liters']),
      petrolPricePerLiter: TripJson.asDouble(json['petrol_price_per_liter']),
      petrolCost: TripJson.asDouble(json['petrol_cost']),
      petrolCostSavings: TripJson.asDouble(json['petrol_cost_savings']),
      co2ReducedKg: TripJson.asDouble(json['co2_reduced_kg']),
    );
  }
}

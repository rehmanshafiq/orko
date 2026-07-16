import 'package:equatable/equatable.dart';

/// Fuel-vs-electric savings for a planned trip, from the `savings` object of
/// `POST /trip-planning/plan-trip/`. All amounts are in the plan's currency;
/// [co2ReducedKg] is the CO₂ avoided by driving electric instead of petrol.
class TripSavingsEntity extends Equatable {
  const TripSavingsEntity({
    required this.petrolLiters,
    required this.petrolPricePerLiter,
    required this.petrolCost,
    required this.petrolCostSavings,
    required this.co2ReducedKg,
  });

  final double petrolLiters;
  final double petrolPricePerLiter;
  final double petrolCost;
  final double petrolCostSavings;
  final double co2ReducedKg;

  @override
  List<Object?> get props => [
        petrolLiters,
        petrolPricePerLiter,
        petrolCost,
        petrolCostSavings,
        co2ReducedKg,
      ];
}

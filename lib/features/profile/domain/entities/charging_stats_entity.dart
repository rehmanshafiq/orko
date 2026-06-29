import 'package:equatable/equatable.dart';

/// Aggregated charging statistics for the logged-in user, from
/// `GET api/v1/bookings/charging-stats/`.
class ChargingStatsEntity extends Equatable {
  const ChargingStatsEntity({
    this.totalCharges = 0,
    this.totalKwh = 0,
    this.totalKm = 0,
    this.co2ReducedKg = 0,
    this.moneySavedPkr = 0,
  });

  final int totalCharges;
  final double totalKwh;
  final double totalKm;
  final double co2ReducedKg;
  final double moneySavedPkr;

  /// All-zero stats — used for guests / brand-new accounts with no sessions.
  static const empty = ChargingStatsEntity();

  @override
  List<Object?> get props => [
        totalCharges,
        totalKwh,
        totalKm,
        co2ReducedKg,
        moneySavedPkr,
      ];
}

import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/profile/domain/entities/charging_stats_entity.dart';

enum ChargingStatsStatus { initial, loading, success, failure }

class ChargingStatsState extends Equatable {
  const ChargingStatsState({
    this.status = ChargingStatsStatus.initial,
    this.stats,
    this.error,
  });

  final ChargingStatsStatus status;
  final ChargingStatsEntity? stats;
  final String? error;

  bool get isLoading => status == ChargingStatsStatus.loading;
  bool get isFailure => status == ChargingStatsStatus.failure;

  ChargingStatsState copyWith({
    ChargingStatsStatus? status,
    ChargingStatsEntity? stats,
    String? error,
  }) {
    return ChargingStatsState(
      status: status ?? this.status,
      stats: stats ?? this.stats,
      error: error,
    );
  }

  @override
  List<Object?> get props => [status, stats, error];
}

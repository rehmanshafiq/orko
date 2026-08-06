import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/profile/domain/entities/charging_stats_entity.dart';
import 'package:orko_hubco/features/profile/domain/usecases/get_charging_stats_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_state.dart';

class ChargingStatsCubit extends Cubit<ChargingStatsState> {
  ChargingStatsCubit({
    required GetChargingStatsUseCase getChargingStats,
    required AnalyticsService analytics,
  })  : _getChargingStats = getChargingStats,
        _analytics = analytics,
        super(const ChargingStatsState());

  final GetChargingStatsUseCase _getChargingStats;
  final AnalyticsService _analytics;

  Future<void> load() async {
    // Guests have no server session — show zeroed stats without hitting the API.
    if (AppStorage.isGuest) {
      const guestStats = ChargingStatsEntity.empty;
      _logStatsView(guestStats);
      emit(const ChargingStatsState(
        status: ChargingStatsStatus.success,
        stats: guestStats,
      ));
      return;
    }

    emit(state.copyWith(status: ChargingStatsStatus.loading));

    final result = await _getChargingStats(const NoParams());

    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        status: ChargingStatsStatus.failure,
        error: failure.message,
      )),
      (stats) {
        _logStatsView(stats);
        emit(ChargingStatsState(
          status: ChargingStatsStatus.success,
          stats: stats,
        ));
      },
    );
  }

  /// Fires `charging_stats_view` once the lifetime stats are resolved and about
  /// to be shown (a retry re-fires it, matching a fresh view of the numbers).
  void _logStatsView(ChargingStatsEntity stats) {
    _analytics.logEvent('charging_stats_view', parameters: {
      'total_sessions': stats.totalCharges,
      'total_kwh': stats.totalKwh,
      'money_saved_pkr': stats.moneySavedPkr,
    });
  }
}

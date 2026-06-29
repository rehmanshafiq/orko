import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/profile/domain/entities/charging_stats_entity.dart';
import 'package:orko_hubco/features/profile/domain/usecases/get_charging_stats_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_state.dart';

class ChargingStatsCubit extends Cubit<ChargingStatsState> {
  ChargingStatsCubit({required GetChargingStatsUseCase getChargingStats})
      : _getChargingStats = getChargingStats,
        super(const ChargingStatsState());

  final GetChargingStatsUseCase _getChargingStats;

  Future<void> load() async {
    // Guests have no server session — show zeroed stats without hitting the API.
    if (AppStorage.isGuest) {
      emit(const ChargingStatsState(
        status: ChargingStatsStatus.success,
        stats: ChargingStatsEntity.empty,
      ));
      return;
    }

    emit(state.copyWith(status: ChargingStatsStatus.loading));

    final result = await _getChargingStats(const NoParams());

    result.fold(
      (failure) => emit(state.copyWith(
        status: ChargingStatsStatus.failure,
        error: failure.message,
      )),
      (stats) => emit(ChargingStatsState(
        status: ChargingStatsStatus.success,
        stats: stats,
      )),
    );
  }
}

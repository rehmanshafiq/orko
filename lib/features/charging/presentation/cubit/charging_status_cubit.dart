import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/charging/presentation/cubit/charging_status_state.dart';

class ChargingStatusCubit extends Cubit<ChargingStatusState> {
  ChargingStatusCubit() : super(ChargingStatusState.initial());

  void startCharging() {
    emit(ChargingStatusState.initial());
  }

  void stopCharging() {
    emit(state.copyWith(status: ChargingSessionStatus.idle));
  }

  void emergencyStop() {
    emit(state.copyWith(status: ChargingSessionStatus.emergency));
  }

  void updateProgress(double value) {
    emit(state.copyWith(sliderValue: value.clamp(0.0, 1.0)));
  }

  void updateMetrics({
    String? stationHeadline,
    double? chargingPercentage,
    String? energyDelivered,
    String? energyDeliveredUnit,
    String? chargingSpeed,
    String? chargingSpeedUnit,
    String? sessionTime,
    String? cost,
    double? sliderValue,
    String? estimatedTimeLabel,
    String? stationInfoText,
    ChargingSessionStatus? status,
  }) {
    emit(
      state.copyWith(
        stationHeadline: stationHeadline,
        chargingPercentage: chargingPercentage,
        energyDelivered: energyDelivered,
        energyDeliveredUnit: energyDeliveredUnit,
        chargingSpeed: chargingSpeed,
        chargingSpeedUnit: chargingSpeedUnit,
        sessionTime: sessionTime,
        cost: cost,
        sliderValue: sliderValue,
        estimatedTimeLabel: estimatedTimeLabel,
        stationInfoText: stationInfoText,
        status: status,
      ),
    );
  }
}

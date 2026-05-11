import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Session UI mode for the center gauge subtitle.
enum ChargingSessionStatus {
  charging,
  idle,
  emergency,
}

class ChargingMetricDisplay extends Equatable {
  const ChargingMetricDisplay({
    required this.label,
    required this.value,
    required this.unit,
    required this.icon,
  });

  final String label;
  final String value;
  final String unit;
  final IconData icon;

  @override
  List<Object?> get props => [label, value, unit, icon];
}

class ChargingStatusState extends Equatable {
  const ChargingStatusState({
    required this.stationHeadline,
    required this.chargingPercentage,
    required this.energyDelivered,
    required this.energyDeliveredUnit,
    required this.chargingSpeed,
    required this.chargingSpeedUnit,
    required this.sessionTime,
    required this.cost,
    required this.sliderValue,
    required this.estimatedTimeLabel,
    required this.stationInfoText,
    required this.status,
  });

  factory ChargingStatusState.initial() {
    return const ChargingStatusState(
      stationHeadline: 'HGL Charging Hub M2 Port 2 CCS',
      chargingPercentage: 67,
      energyDelivered: '8.4',
      energyDeliveredUnit: 'kWh',
      chargingSpeed: '150',
      chargingSpeedUnit: 'kW',
      sessionTime: '00:33:42',
      cost: 'Rs 378',
      sliderValue: 0.80,
      estimatedTimeLabel: 'Est. Full Charge in 16 min',
      stationInfoText: 'Station Info - HGL Charging Hub M2',
      status: ChargingSessionStatus.charging,
    );
  }

  final String stationHeadline;
  final double chargingPercentage;
  final String energyDelivered;
  final String energyDeliveredUnit;
  final String chargingSpeed;
  final String chargingSpeedUnit;
  final String sessionTime;
  final String cost;
  final double sliderValue;
  final String estimatedTimeLabel;
  final String stationInfoText;
  final ChargingSessionStatus status;

  double get gaugeProgress =>
      (chargingPercentage / 100).clamp(0.0, 1.0).toDouble();

  String get gaugePercentLabel {
    final v = chargingPercentage.round();
    return '$v%';
  }

  String get statusLabel {
    switch (status) {
      case ChargingSessionStatus.charging:
        return 'Charging';
      case ChargingSessionStatus.idle:
        return 'Idle';
      case ChargingSessionStatus.emergency:
        return 'Emergency';
    }
  }

  String get targetPercentLabel =>
      '${(sliderValue * 100).round()}% Target';

  List<ChargingMetricDisplay> get metrics => [
        ChargingMetricDisplay(
          label: 'Energy Delivered',
          value: energyDelivered,
          unit: energyDeliveredUnit,
          icon: Icons.battery_4_bar_rounded,
        ),
        ChargingMetricDisplay(
          label: 'Charging Speed',
          value: chargingSpeed,
          unit: chargingSpeedUnit,
          icon: Icons.bolt_rounded,
        ),
        ChargingMetricDisplay(
          label: 'Session Time',
          value: sessionTime,
          unit: '',
          icon: Icons.access_time_rounded,
        ),
        ChargingMetricDisplay(
          label: 'Current Cost',
          value: cost,
          unit: '',
          icon: Icons.payments_outlined,
        ),
      ];

  /// Null field means keep previous value (partial update).
  ChargingStatusState copyWith({
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
    return ChargingStatusState(
      stationHeadline: stationHeadline ?? this.stationHeadline,
      chargingPercentage: chargingPercentage ?? this.chargingPercentage,
      energyDelivered: energyDelivered ?? this.energyDelivered,
      energyDeliveredUnit: energyDeliveredUnit ?? this.energyDeliveredUnit,
      chargingSpeed: chargingSpeed ?? this.chargingSpeed,
      chargingSpeedUnit: chargingSpeedUnit ?? this.chargingSpeedUnit,
      sessionTime: sessionTime ?? this.sessionTime,
      cost: cost ?? this.cost,
      sliderValue: sliderValue ?? this.sliderValue,
      estimatedTimeLabel: estimatedTimeLabel ?? this.estimatedTimeLabel,
      stationInfoText: stationInfoText ?? this.stationInfoText,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
        stationHeadline,
        chargingPercentage,
        energyDelivered,
        energyDeliveredUnit,
        chargingSpeed,
        chargingSpeedUnit,
        sessionTime,
        cost,
        sliderValue,
        estimatedTimeLabel,
        stationInfoText,
        status,
      ];
}

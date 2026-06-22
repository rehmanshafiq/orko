import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_make_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_model_entity.dart';

enum VehicleStatus { initial, loading, success, failure }

class VehicleState extends Equatable {
  const VehicleState({
    this.vehiclesStatus = VehicleStatus.initial,
    this.vehicles = const [],
    this.vehiclesError,
    this.makesStatus = VehicleStatus.initial,
    this.makes = const [],
    this.makesError,
    this.modelsStatus = VehicleStatus.initial,
    this.models = const [],
    this.modelsError,
    this.isSubmitting = false,
  });

  // ── User's vehicles (Vehicles tab) ──────────────────────────────────────
  final VehicleStatus vehiclesStatus;
  final List<UserVehicleEntity> vehicles;
  final String? vehiclesError;

  // ── Makes dropdown (Add dialog) ─────────────────────────────────────────
  final VehicleStatus makesStatus;
  final List<VehicleMakeEntity> makes;
  final String? makesError;

  // ── Models dropdown (Add dialog) ────────────────────────────────────────
  final VehicleStatus modelsStatus;
  final List<VehicleModelEntity> models;
  final String? modelsError;

  /// True while an add-vehicle request is in flight.
  final bool isSubmitting;

  VehicleState copyWith({
    VehicleStatus? vehiclesStatus,
    List<UserVehicleEntity>? vehicles,
    String? vehiclesError,
    bool clearVehiclesError = false,
    VehicleStatus? makesStatus,
    List<VehicleMakeEntity>? makes,
    String? makesError,
    bool clearMakesError = false,
    VehicleStatus? modelsStatus,
    List<VehicleModelEntity>? models,
    String? modelsError,
    bool clearModelsError = false,
    bool? isSubmitting,
  }) {
    return VehicleState(
      vehiclesStatus: vehiclesStatus ?? this.vehiclesStatus,
      vehicles: vehicles ?? this.vehicles,
      vehiclesError:
          clearVehiclesError ? null : (vehiclesError ?? this.vehiclesError),
      makesStatus: makesStatus ?? this.makesStatus,
      makes: makes ?? this.makes,
      makesError: clearMakesError ? null : (makesError ?? this.makesError),
      modelsStatus: modelsStatus ?? this.modelsStatus,
      models: models ?? this.models,
      modelsError: clearModelsError ? null : (modelsError ?? this.modelsError),
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [
        vehiclesStatus,
        vehicles,
        vehiclesError,
        makesStatus,
        makes,
        makesError,
        modelsStatus,
        models,
        modelsError,
        isSubmitting,
      ];
}

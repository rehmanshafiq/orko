import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_make_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/vehicle_model_entity.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/add_vehicle_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/create_custom_make_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/create_custom_model_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/delete_vehicle_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_user_vehicles_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_vehicle_makes_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_vehicle_models_usecase.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_state.dart';

/// Outcome of add-vehicle, surfaced to the dialog for snackbars/closing.
typedef VehicleActionResult = ({bool success, String message});

/// Outcome of creating a custom make (carries the new make on success).
typedef CustomMakeResult = ({bool success, String message, VehicleMakeEntity? make});

/// Outcome of creating a custom model (carries the new model on success).
typedef CustomModelResult = ({bool success, String message, VehicleModelEntity? model});

class VehicleCubit extends Cubit<VehicleState> {
  VehicleCubit({
    required GetVehicleMakesUseCase getMakesUseCase,
    required GetVehicleModelsUseCase getModelsUseCase,
    required AddVehicleUseCase addVehicleUseCase,
    required GetUserVehiclesUseCase getUserVehiclesUseCase,
    required DeleteVehicleUseCase deleteVehicleUseCase,
    required CreateCustomMakeUseCase createCustomMakeUseCase,
    required CreateCustomModelUseCase createCustomModelUseCase,
  })  : _getMakesUseCase = getMakesUseCase,
        _getModelsUseCase = getModelsUseCase,
        _addVehicleUseCase = addVehicleUseCase,
        _getUserVehiclesUseCase = getUserVehiclesUseCase,
        _deleteVehicleUseCase = deleteVehicleUseCase,
        _createCustomMakeUseCase = createCustomMakeUseCase,
        _createCustomModelUseCase = createCustomModelUseCase,
        super(const VehicleState());

  final GetVehicleMakesUseCase _getMakesUseCase;
  final GetVehicleModelsUseCase _getModelsUseCase;
  final AddVehicleUseCase _addVehicleUseCase;
  final GetUserVehiclesUseCase _getUserVehiclesUseCase;
  final DeleteVehicleUseCase _deleteVehicleUseCase;
  final CreateCustomMakeUseCase _createCustomMakeUseCase;
  final CreateCustomModelUseCase _createCustomModelUseCase;

  /// Loads the user's vehicles for the Vehicles tab. Guests have no server
  /// session, so we surface an empty list rather than an Unauthorized error.
  Future<void> loadUserVehicles({bool showSpinner = true}) async {
    if (AppStorage.isGuest) {
      emit(state.copyWith(
        vehiclesStatus: VehicleStatus.success,
        vehicles: const [],
        clearVehiclesError: true,
      ));
      return;
    }

    if (showSpinner) {
      emit(state.copyWith(
        vehiclesStatus: VehicleStatus.loading,
        clearVehiclesError: true,
      ));
    }

    final result = await _getUserVehiclesUseCase(const NoParams());
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        vehiclesStatus: VehicleStatus.failure,
        vehiclesError: failure.message,
      )),
      (vehicles) => emit(state.copyWith(
        vehiclesStatus: VehicleStatus.success,
        vehicles: vehicles,
        clearVehiclesError: true,
      )),
    );
  }

  /// Loads makes for the "Select Make" dropdown.
  Future<void> loadMakes() async {
    emit(state.copyWith(
      makesStatus: VehicleStatus.loading,
      clearMakesError: true,
    ));
    final result = await _getMakesUseCase(const NoParams());
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        makesStatus: VehicleStatus.failure,
        makesError: failure.message,
      )),
      (makes) => emit(state.copyWith(
        makesStatus: VehicleStatus.success,
        makes: makes,
        clearMakesError: true,
      )),
    );
  }

  /// Loads models for [makeId]. Clears any previously loaded models first so a
  /// stale list can't briefly show for the new make.
  Future<void> loadModels(int makeId) async {
    emit(state.copyWith(
      modelsStatus: VehicleStatus.loading,
      models: const [],
      clearModelsError: true,
    ));
    final result =
        await _getModelsUseCase(GetVehicleModelsParams(makeId: makeId));
    if (isClosed) return;
    result.fold(
      (failure) => emit(state.copyWith(
        modelsStatus: VehicleStatus.failure,
        modelsError: failure.message,
      )),
      (models) => emit(state.copyWith(
        modelsStatus: VehicleStatus.success,
        models: models,
        clearModelsError: true,
      )),
    );
  }

  /// Resets the models section (used when the make changes or dialog opens).
  void resetModels() {
    emit(state.copyWith(
      modelsStatus: VehicleStatus.initial,
      models: const [],
      clearModelsError: true,
    ));
  }

  /// Creates a custom make and appends it to the makes list so it can be
  /// selected immediately. Returns the created make on success.
  Future<CustomMakeResult> createCustomMake(String name) async {
    if (state.isCreatingMake) {
      return (success: false, message: 'Please wait…', make: null);
    }
    emit(state.copyWith(isCreatingMake: true));
    final result = await _createCustomMakeUseCase(name);
    if (isClosed) return (success: false, message: '', make: null);
    return result.fold(
      (failure) {
        emit(state.copyWith(isCreatingMake: false));
        return (success: false, message: failure.message, make: null);
      },
      (make) {
        // Append (avoid duplicates) so the dropdown immediately offers it.
        final makes = [
          ...state.makes.where((m) => m.id != make.id),
          make,
        ];
        emit(state.copyWith(
          isCreatingMake: false,
          makes: makes,
          makesStatus: VehicleStatus.success,
          clearMakesError: true,
        ));
        return (success: true, message: 'Make added.', make: make);
      },
    );
  }

  /// Creates a custom model under [mdMake] and appends it to the models list so
  /// it can be selected immediately. Returns the created model on success.
  Future<CustomModelResult> createCustomModel({
    required int mdMake,
    required String name,
    required String connectorType,
    required double batteryCapacity,
    required int mileage,
  }) async {
    if (state.isCreatingModel) {
      return (success: false, message: 'Please wait…', model: null);
    }
    emit(state.copyWith(isCreatingModel: true));
    final result = await _createCustomModelUseCase(CreateCustomModelParams(
      mdMake: mdMake,
      name: name,
      connectorType: connectorType,
      batteryCapacity: batteryCapacity,
      mileage: mileage,
    ));
    if (isClosed) return (success: false, message: '', model: null);
    return result.fold(
      (failure) {
        emit(state.copyWith(isCreatingModel: false));
        return (success: false, message: failure.message, model: null);
      },
      (model) {
        final models = [
          ...state.models.where((m) => m.id != model.id),
          model,
        ];
        emit(state.copyWith(
          isCreatingModel: false,
          models: models,
          modelsStatus: VehicleStatus.success,
          clearModelsError: true,
        ));
        return (success: true, message: 'Model added.', model: model);
      },
    );
  }

  /// Creates a vehicle, then silently refreshes the user's vehicle list.
  Future<VehicleActionResult> addVehicle({
    required int mdMake,
    required int mdModel,
    required String year,
    String? vehicleRfid,
  }) async {
    if (state.isSubmitting) {
      return (success: false, message: 'Please wait for the current action.');
    }
    emit(state.copyWith(isSubmitting: true));

    final result = await _addVehicleUseCase(AddVehicleParams(
      mdMake: mdMake,
      mdModel: mdModel,
      year: year,
      vehicleRfid: vehicleRfid,
    ));

    if (isClosed) return (success: false, message: 'Vehicle created.');
    return result.fold(
      (failure) {
        emit(state.copyWith(isSubmitting: false));
        return (success: false, message: failure.message);
      },
      (_) async {
        emit(state.copyWith(isSubmitting: false));
        await loadUserVehicles(showSpinner: false);
        return (success: true, message: 'Vehicle added.');
      },
    );
  }

  /// Soft-deletes [vehicleId], then silently refreshes the vehicle list.
  ///
  /// On the API's "Vehicle not found." case (already deleted / not the user's)
  /// we still refresh so the list reflects the server's truth.
  Future<VehicleActionResult> deleteVehicle(int vehicleId) async {
    if (state.deletingId != null) {
      return (success: false, message: 'Please wait for the current action.');
    }
    emit(state.copyWith(deletingId: vehicleId));

    final result =
        await _deleteVehicleUseCase(DeleteVehicleParams(id: vehicleId));

    if (isClosed) return (success: false, message: 'Vehicle deleted.');
    return result.fold(
      (failure) {
        emit(state.copyWith(clearDeletingId: true));
        return (success: false, message: failure.message);
      },
      (_) async {
        await loadUserVehicles(showSpinner: false);
        if (!isClosed) emit(state.copyWith(clearDeletingId: true));
        return (success: true, message: 'Vehicle deleted.');
      },
    );
  }
}

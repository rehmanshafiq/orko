import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/add_vehicle_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_user_vehicles_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_vehicle_makes_usecase.dart';
import 'package:orko_hubco/features/vehicle/domain/usecases/get_vehicle_models_usecase.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_state.dart';

/// Outcome of add-vehicle, surfaced to the dialog for snackbars/closing.
typedef VehicleActionResult = ({bool success, String message});

class VehicleCubit extends Cubit<VehicleState> {
  VehicleCubit({
    required GetVehicleMakesUseCase getMakesUseCase,
    required GetVehicleModelsUseCase getModelsUseCase,
    required AddVehicleUseCase addVehicleUseCase,
    required GetUserVehiclesUseCase getUserVehiclesUseCase,
  })  : _getMakesUseCase = getMakesUseCase,
        _getModelsUseCase = getModelsUseCase,
        _addVehicleUseCase = addVehicleUseCase,
        _getUserVehiclesUseCase = getUserVehiclesUseCase,
        super(const VehicleState());

  final GetVehicleMakesUseCase _getMakesUseCase;
  final GetVehicleModelsUseCase _getModelsUseCase;
  final AddVehicleUseCase _addVehicleUseCase;
  final GetUserVehiclesUseCase _getUserVehiclesUseCase;

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
}

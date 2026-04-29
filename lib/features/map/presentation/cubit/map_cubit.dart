import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/domain/usecases/get_hubco_locations_usecase.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';

class MapCubit extends Cubit<MapState> {
  final GetHubcoLocationsUseCase _getHubcoLocationsUseCase;

  MapCubit({required GetHubcoLocationsUseCase getHubcoLocationsUseCase})
      : _getHubcoLocationsUseCase = getHubcoLocationsUseCase,
        super(const MapInitial());

  Future<void> loadHubcoLocations() async {
    emit(const MapLoading());

    final result = await _getHubcoLocationsUseCase(const NoParams());
    result.fold(
      (failure) => emit(MapError(failure.message)),
      (locations) => emit(MapLoaded(locations)),
    );
  }
}

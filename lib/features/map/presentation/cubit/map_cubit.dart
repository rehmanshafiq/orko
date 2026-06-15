import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orko_hubco/features/map/domain/usecases/get_hubco_locations_usecase.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';

class MapCubit extends Cubit<MapState> {
  final GetHubcoLocationsUseCase _getHubcoLocationsUseCase;

  MapCubit({required GetHubcoLocationsUseCase getHubcoLocationsUseCase})
      : _getHubcoLocationsUseCase = getHubcoLocationsUseCase,
        super(const MapInitial());

  /// Default coordinates (Karachi) used when the device location is unavailable.
  static const double _defaultLatitude = 24.8607;
  static const double _defaultLongitude = 67.0011;

  /// Resolves the device's current location (best-effort) and loads the nearest
  /// charging stations around it. Falls back to a default location if the
  /// device position can't be determined.
  Future<void> loadHubcoLocations() async {
    emit(const MapLoading());

    final position = await _resolveCurrentPosition();

    final result = await _getHubcoLocationsUseCase(
      NearestStationsParams(
        latitude: position?.latitude ?? _defaultLatitude,
        longitude: position?.longitude ?? _defaultLongitude,
      ),
    );

    result.fold(
      (failure) => emit(MapError(failure.message)),
      (locations) => emit(MapLoaded(locations)),
    );
  }

  Future<Position?> _resolveCurrentPosition() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition();
    } catch (e) {
      log('[Map] Failed to resolve current position: $e');
      return null;
    }
  }
}

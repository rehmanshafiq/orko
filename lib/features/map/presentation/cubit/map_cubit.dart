import 'dart:developer';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filters.dart';
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

  /// Currently applied filters (empty by default). Exposed so the filter sheet
  /// can pre-select what's active when it reopens.
  StationFilters _filters = const StationFilters();
  StationFilters get currentFilters => _filters;

  /// Cached last-resolved position so re-filtering doesn't re-prompt GPS.
  double? _lastLatitude;
  double? _lastLongitude;

  /// Resolves the device's current location (best-effort) and loads the nearest
  /// charging stations around it. Falls back to a default location if the
  /// device position can't be determined.
  Future<void> loadHubcoLocations() {
    return _load(resolvePosition: true);
  }

  /// Applies [filters] and reloads the stations. Reuses the cached position so
  /// the user isn't re-prompted for location on every filter change.
  Future<void> applyFilters(StationFilters filters) {
    _filters = filters;
    return _load(resolvePosition: _lastLatitude == null);
  }

  Future<void> _load({required bool resolvePosition}) async {
    emit(const MapLoading());

    if (resolvePosition) {
      final position = await _resolveCurrentPosition();
      _lastLatitude = position?.latitude ?? _defaultLatitude;
      _lastLongitude = position?.longitude ?? _defaultLongitude;
    }

    final filters = _filters;
    final result = await _getHubcoLocationsUseCase(
      NearestStationsParams(
        latitude: _lastLatitude ?? _defaultLatitude,
        longitude: _lastLongitude ?? _defaultLongitude,
        radius: filters.radius,
        connectorTypes:
            filters.connectorTypes.isEmpty ? null : filters.connectorTypes,
        amenityIds: filters.amenityIds.isEmpty ? null : filters.amenityIds,
        minPrice: filters.minPrice,
        maxPrice: filters.maxPrice,
        powerOutput: filters.powerOutput,
        city: filters.city,
      ),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(MapError(failure.message)),
      (locations) {
        // "Available Now" has no API param — apply it client-side.
        final visible = filters.availableNow
            ? locations
                .where((l) => l.availableConnectors > 0)
                .toList(growable: false)
            : locations;
        emit(MapLoaded(visible));
      },
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

      // Never block the loader indefinitely on a cold GPS fix; fall back to the
      // default location if a position can't be obtained in time.
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      log('[Map] Failed to resolve current position: $e');
      return null;
    }
  }
}

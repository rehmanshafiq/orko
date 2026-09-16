import 'dart:ui' show DartPluginRegistrant;

import 'package:dio/dio.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get_storage/get_storage.dart';

import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/core/network/certificate_pinning.dart';
import 'package:orko_hubco/core/services/secure_store.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';
import 'package:orko_hubco/features/booking/data/datasources/remote/booking_remote_datasource_impl.dart';
import 'package:orko_hubco/features/booking/domain/entities/live_session_entity.dart';
import 'package:orko_hubco/features/charging/data/datasources/remote/charging_remote_datasource.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';
import 'package:orko_hubco/features/map/data/datasources/remote/map_remote_datasource.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/trip/data/datasources/remote/trip_remote_datasource_impl.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_stop_entity.dart';
import 'package:orko_hubco/firebase_options.dart';

/// Dedicated Dart entrypoint for the Android Auto car app.
///
/// The native [CarAppService] (Kotlin) runs this on its own cached
/// [FlutterEngine], independently of `MainActivity`. It exposes READ-ONLY
/// display data to the car over the `orko/android_auto` [MethodChannel],
/// reusing the app's real network/auth/config stack so every request is
/// byte-for-byte identical to the phone (auth header, `Domain` header, cert
/// pinning, Remote Config endpoints, models).
///
/// SECURITY: the access token never crosses the channel — it stays inside
/// [SecureStore]/[ApiClient] here. Only sanitized display maps are returned.
///
/// Wires up the Android Auto MethodChannel on the car engine's isolate.
///
/// Called from the top-level `androidAutoMain` entrypoint declared in
/// `lib/main.dart` (the root library is always compiled and its entrypoints are
/// resolvable by name from native; an orphan library here would not be compiled
/// into the app at all).
void startAndroidAutoBridge() {
  WidgetsFlutterBinding.ensureInitialized();
  // Register plugins in this engine's isolate (dio/secure_storage/geolocator/…).
  DartPluginRegistrant.ensureInitialized();

  final bridge = _AndroidAutoBridge();
  const channel = MethodChannel('orko/android_auto');
  channel.setMethodCallHandler(bridge.handle);
  AppLogger.d('[AndroidAuto] entrypoint ready; channel orko/android_auto bound');
}

/// Short, stable error codes sent to Kotlin (never raw messages / stack traces).
class _Err {
  static const auth = 'auth';
  static const network = 'network';
  static const location = 'location';
  static const server = 'server';
}

class _AndroidAutoBridge {
  ApiClient? _client;
  bool _bootstrapped = false;

  MapRemoteDataSourceImpl get _map =>
      MapRemoteDataSourceImpl(apiClient: _client!);
  ChargingRemoteDataSourceImpl get _charging =>
      ChargingRemoteDataSourceImpl(apiClient: _client!);
  BookingRemoteDataSourceImpl get _booking =>
      BookingRemoteDataSourceImpl(apiClient: _client!);
  TripRemoteDataSourceImpl get _trip =>
      TripRemoteDataSourceImpl(apiClient: _client!);

  /// Re-initialises the minimal stack the requests need, exactly once. Mirrors
  /// [LiveSessionFetcher] so this works in the car engine's isolate, which
  /// starts with none of the app's singletons initialised. Every step is
  /// idempotent.
  Future<void> _bootstrap() async {
    if (_bootstrapped) return;

    await GetStorage.init();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (_) {
      // Already initialised in this isolate — ignore.
    }

    // Resolves base URL + endpoint paths (Firebase → cache → asset). Never
    // fatal: ApiClient.baseUrl still has a compile-time fallback.
    try {
      await RemoteConfigService.instance.initialize();
    } catch (e) {
      AppLogger.d('[AndroidAuto] remote config init failed: $e');
    }

    // Loads the encrypted token mirror the AuthInterceptor reads synchronously.
    await SecureStore.instance.init();

    // Pinned CA bundle (no-op in debug); must precede ApiClient so the pinned
    // adapter is wired into Dio.
    await CertificatePinning.load();

    _client = ApiClient();
    _bootstrapped = true;
  }

  /// Whether a session token exists locally (no network round-trip).
  bool get _hasToken {
    final token = SecureStore.instance.read(StorageConstants.accessToken);
    return token != null && token.trim().isNotEmpty;
  }

  /// Entry for every channel call. Catches everything and returns a typed
  /// result map — it must NEVER throw across the platform channel.
  Future<Object?> handle(MethodCall call) async {
    try {
      await _bootstrap();
    } catch (e) {
      AppLogger.d('[AndroidAuto] bootstrap failed: $e');
      // Bootstrap failure is treated as a server error for data calls; auth
      // check can still answer from a partial state below.
    }

    switch (call.method) {
      case 'isAuthenticated':
        return {'authenticated': _hasToken};
      case 'getNearbyStations':
        return _getNearbyStations(call.arguments);
      case 'getStationDetail':
        return _getStationDetail(call.arguments);
      case 'getLiveSession':
        return _getLiveSession();
      case 'getSavedTrips':
        return _getSavedTrips();
      case 'getSavedTripDetail':
        return _getSavedTripDetail(call.arguments);
      default:
        return {'ok': false, 'error': _Err.server};
    }
  }

  // ── Handlers ────────────────────────────────────────────────────────────

  Future<Map<String, Object?>> _getNearbyStations(Object? args) async {
    if (!_hasToken) return {'ok': false, 'error': _Err.auth};
    if (_client == null) return {'ok': false, 'error': _Err.server};

    final a = _asMap(args);
    double? lat = _asDouble(a['lat']);
    double? lng = _asDouble(a['lng']);

    if (lat == null || lng == null) {
      final pos = await _resolvePosition();
      if (pos == null) return {'ok': false, 'error': _Err.location};
      lat = pos.latitude;
      lng = pos.longitude;
    }

    try {
      final stations = await _map.getNearestStations(latitude: lat, longitude: lng);
      return {
        'ok': true,
        'stations': stations.map(_stationRow).toList(),
      };
    } catch (e) {
      return {'ok': false, 'error': _codeFor(e)};
    }
  }

  Future<Map<String, Object?>> _getStationDetail(Object? args) async {
    if (!_hasToken) return {'ok': false, 'error': _Err.auth};
    if (_client == null) return {'ok': false, 'error': _Err.server};

    final a = _asMap(args);
    final id = a['id']?.toString();
    if (id == null || id.isEmpty) return {'ok': false, 'error': _Err.server};
    final lat = _asDouble(a['lat']) ?? 0;
    final lng = _asDouble(a['lng']) ?? 0;

    try {
      final s = await _charging.getStationDetail(
        stationId: id,
        latitude: lat,
        longitude: lng,
      );
      return {'ok': true, 'station': _stationDetail(s)};
    } catch (e) {
      return {'ok': false, 'error': _codeFor(e)};
    }
  }

  Future<Map<String, Object?>> _getLiveSession() async {
    if (!_hasToken) return {'ok': false, 'error': _Err.auth};
    if (_client == null) return {'ok': false, 'error': _Err.server};

    try {
      final s = await _booking.getLiveSession();
      if (!s.active) return {'ok': true, 'active': false};
      return {'ok': true, 'active': true, 'session': _liveSession(s)};
    } catch (e) {
      return {'ok': false, 'error': _codeFor(e)};
    }
  }

  Future<Map<String, Object?>> _getSavedTrips() async {
    if (!_hasToken) return {'ok': false, 'error': _Err.auth};
    if (_client == null) return {'ok': false, 'error': _Err.server};

    try {
      final trips = await _trip.getSavedTrips();
      return {'ok': true, 'trips': trips.map(_tripRow).toList()};
    } catch (e) {
      return {'ok': false, 'error': _codeFor(e)};
    }
  }

  Future<Map<String, Object?>> _getSavedTripDetail(Object? args) async {
    if (!_hasToken) return {'ok': false, 'error': _Err.auth};
    if (_client == null) return {'ok': false, 'error': _Err.server};

    final a = _asMap(args);
    final id = _asInt(a['id']);
    if (id == null) return {'ok': false, 'error': _Err.server};

    try {
      final t = await _trip.getSavedTripDetail(id);
      return {'ok': true, 'trip': _tripDetail(t)};
    } catch (e) {
      return {'ok': false, 'error': _codeFor(e)};
    }
  }

  // ── Serialization (sanitized display data only) ───────────────────────────

  Map<String, Object?> _stationRow(HubcoLocationEntity s) => {
        'id': s.id,
        'name': s.name,
        'address': s.address,
        'distanceKm': s.distance,
        'available': s.available,
        'availableConnectors': s.availableConnectors,
        'numberOfConnectors': s.numberOfConnectors,
        'connectorTypes': s.connectorTypes,
        'powerKw': s.powerOutputs,
        'priceLabel': _priceLabelFromList(s.prices),
        'lat': s.latitude,
        'lng': s.longitude,
      };

  Map<String, Object?> _stationDetail(ChargingStationDetailEntity s) {
    final connectors = <Map<String, Object?>>[];
    for (final charger in s.chargers) {
      for (final c in charger.connectors) {
        connectors.add({
          'type': c.connectorType,
          'powerKw': c.power,
          'priceLabel': _connectorPriceLabel(c.price),
          'state': c.connectorState,
        });
      }
    }
    return {
      'id': s.locationId,
      'name': s.name,
      'address': s.address,
      'open': s.status && !s.isClosed,
      'openingTime': s.openingTime,
      'closingTime': s.closingTime,
      'distanceKm': s.distance,
      'connectors': connectors,
      'averageRating': s.averageRating,
      'contactNumber': s.contactNumber,
      'lat': s.latitude,
      'lng': s.longitude,
    };
  }

  Map<String, Object?> _liveSession(LiveSessionEntity s) => {
        'locationName': s.locationName,
        'percent': s.currentChargePercentage,
        'speedKw': s.chargingSpeedKw,
        'energyKwh': s.energyDeliveredKwh,
        'timeLeft': s.timeLeft,
        'cost': s.currentCost,
      };

  Map<String, Object?> _tripRow(SavedTripEntity t) => {
        'id': t.id,
        'title': _tripTitle(t.originAddress, t.destinationAddress, t.id),
        'originAddress': t.originAddress,
        'destinationAddress': t.destinationAddress,
        'totalDistanceKm': t.totalDistanceKm,
        'totalDriveMinutes': t.totalDriveMinutes,
        'totalChargingMinutes': t.totalChargingMinutes,
        'totalCost': t.totalCost,
        'currency': t.currency,
        'stopCount': t.stops.length,
      };

  Map<String, Object?> _tripDetail(SavedTripEntity t) => {
        'id': t.id,
        'title': _tripTitle(t.originAddress, t.destinationAddress, t.id),
        'originAddress': t.originAddress,
        'destinationAddress': t.destinationAddress,
        'totalDistanceKm': t.totalDistanceKm,
        'totalDriveMinutes': t.totalDriveMinutes,
        'totalChargingMinutes': t.totalChargingMinutes,
        'totalCost': t.totalCost,
        'currency': t.currency,
        'stops': t.stops.map(_tripStop).toList(),
      };

  Map<String, Object?> _tripStop(TripStopEntity s) => {
        'sequence': s.sequence,
        'locationName': s.locationName,
        'locationAddress': s.locationAddress,
        'lat': s.latitude,
        'lng': s.longitude,
        'connectorType': s.connectorType,
        'powerKw': s.connectorPowerKw,
        'arrivalSoc': s.arrivalSoc,
        'departureSoc': s.departureSoc,
        'chargingMinutes': s.chargingMinutes,
        'cost': s.cost,
      };

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _tripTitle(String? origin, String? destination, int id) {
    final o = origin?.trim();
    final d = destination?.trim();
    if (o != null && o.isNotEmpty && d != null && d.isNotEmpty) return '$o → $d';
    if (d != null && d.isNotEmpty) return d;
    if (o != null && o.isNotEmpty) return o;
    return 'Trip #$id';
  }

  String _priceLabelFromList(List<StationPriceEntity> prices) {
    if (prices.isEmpty) return '';
    final p = prices.first;
    return _priceLabel(p.currency, p.price, p.pricingMode);
  }

  String _connectorPriceLabel(ConnectorPriceEntity? p) {
    if (p == null) return '';
    return _priceLabel(p.currency, p.price, p.pricingMode);
  }

  String _priceLabel(String currency, double price, String mode) {
    final cur = currency.trim();
    final m = mode.trim();
    final amount = price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toStringAsFixed(2);
    final head = cur.isNotEmpty ? '$cur $amount' : amount;
    return m.isNotEmpty ? '$head/$m' : head;
  }

  /// Resolves the current position, mirroring the map cubit's guard. Returns
  /// null on any failure (service off, permission denied, timeout).
  Future<Position?> _resolvePosition() async {
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

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
    } catch (e) {
      AppLogger.d('[AndroidAuto] position resolve failed: $e');
      return null;
    }
  }

  /// Maps an exception to a short error code. Never surfaces raw messages.
  String _codeFor(Object e) {
    if (e is UnauthorizedException) return _Err.auth;
    if (e is NetworkException) return _Err.network;
    if (e is ServerException) {
      if (e.statusCode == 401) return _Err.auth;
      final orig = e.originalError;
      if (orig is DioException && _isNetworkDioError(orig)) return _Err.network;
      return _Err.server;
    }
    if (e is DioException) {
      if (e.response?.statusCode == 401) return _Err.auth;
      if (_isNetworkDioError(e)) return _Err.network;
    }
    return _Err.server;
  }

  bool _isNetworkDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return true;
      default:
        return false;
    }
  }

  Map<String, Object?> _asMap(Object? args) {
    if (args is Map) {
      return args.map((k, v) => MapEntry(k.toString(), v));
    }
    return const {};
  }

  double? _asDouble(Object? v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  int? _asInt(Object? v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}

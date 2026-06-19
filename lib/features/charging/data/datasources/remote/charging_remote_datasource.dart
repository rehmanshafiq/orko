import 'dart:developer';

import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/charging/data/models/charging_station_detail_model.dart';
import 'package:orko_hubco/features/charging/data/models/favourite_station_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

abstract class ChargingRemoteDataSource {
  /// Fetches the full detail for [stationId] using the QA base URL and the
  /// `charging_station_detail` endpoint resolved from Remote Config.
  Future<ChargingStationDetailModel> getStationDetail({
    required String stationId,
    required double latitude,
    required double longitude,
  });

  /// Fetches the user's favourite charging stations
  /// (`GET api/v1/charging-station/favourites/`).
  Future<List<FavouriteStationModel>> getFavourites();

  /// Adds [locationId] to the user's favourites
  /// (`POST api/v1/charging-station/favourites/`).
  Future<void> addFavourite(int locationId);

  /// Removes [locationId] from the user's favourites
  /// (`DELETE api/v1/charging-station/favourites/?location_id=...`).
  Future<void> removeFavourite(int locationId);
}

class ChargingRemoteDataSourceImpl implements ChargingRemoteDataSource {
  final ApiClient apiClient;

  const ChargingRemoteDataSourceImpl({required this.apiClient});

  /// Default favourites path, used when Remote Config doesn't provide the
  /// `charging_station_favourites` key (e.g. the Firebase parameter hasn't been
  /// updated yet). Keeps the feature working off the bundled contract.
  static const String _defaultFavouritesPath =
      'api/v1/charging-station/favourites/';

  @override
  Future<ChargingStationDetailModel> getStationDetail({
    required String stationId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final url = _buildUrl(
        config.apiConstants.baseUrlLive,
        config.apiConstants.apiEndpoints.chargingStationDetail,
        stationId,
      );

      log('[Charging] Station detail URL: $url '
          '(lat: $latitude, long: $longitude)');

      final response = await apiClient.get(
        url,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is Map) {
          final station = body['station'];
          if (station is Map) {
            return ChargingStationDetailModel.fromJson(
              Map<String, dynamic>.from(station),
            );
          }
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to load station detail',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<List<FavouriteStationModel>> getFavourites() async {
    try {
      final url = _favouritesUrl();
      log('[Charging] Favourites URL (GET): $url');

      final response = await apiClient.get(url);

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is List) {
          return body
              .whereType<Map>()
              .map((e) => FavouriteStationModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList(growable: false);
        }
        // A successful response with no favourites is a valid empty list.
        return const [];
      }

      throw ServerException(
        message: _messageOf(data, 'Failed to load favourites'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> addFavourite(int locationId) async {
    try {
      final url = _favouritesUrl();
      log('[Charging] Favourites URL (POST): $url (location_id: $locationId)');

      final response = await apiClient.post(
        url,
        data: {'location_id': locationId},
      );

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return;

      throw ServerException(
        message: _messageOf(response.data, 'Failed to add favourite'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> removeFavourite(int locationId) async {
    try {
      final url = _favouritesUrl();
      log('[Charging] Favourites URL (DELETE): $url (location_id: $locationId)');

      final response = await apiClient.delete(
        url,
        queryParameters: {'location_id': locationId},
      );

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return;

      throw ServerException(
        message: _messageOf(response.data, 'Failed to remove favourite'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Joins the base URL, endpoint path, and station id into a single clean URL.
  /// e.g. base + `api/v1/charging-station/` + `6` → `.../api/v1/charging-station/6`.
  String _buildUrl(String baseUrl, String endpoint, String stationId) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    var path = endpoint.trim();
    if (path.endsWith('?')) path = path.substring(0, path.length - 1);
    if (path.startsWith('/')) path = path.substring(1);
    if (path.endsWith('/')) path = path.substring(0, path.length - 1);
    return '$base/$path/$stationId';
  }

  /// Resolves the favourites endpoint against the QA base URL.
  String _favouritesUrl() {
    final config = RemoteConfigService.config;
    if (config == null) {
      throw const ServerException(message: 'Remote config not initialized');
    }
    final base = config.apiConstants.baseUrlLive.endsWith('/')
        ? config.apiConstants.baseUrlLive
            .substring(0, config.apiConstants.baseUrlLive.length - 1)
        : config.apiConstants.baseUrlLive;
    var path = config.apiConstants.apiEndpoints.chargingStationFavourites.trim();
    if (path.isEmpty) path = _defaultFavouritesPath;
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
  }

  /// Extracts a human-readable message from an error response body.
  String _messageOf(dynamic data, String fallback) {
    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }
}

import 'dart:developer';

import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/map/data/models/hubco_location_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

abstract class MapRemoteDataSource {
  /// Fetches nearest charging stations around [latitude]/[longitude] using the
  /// QA base URL and endpoint resolved from Remote Config.
  Future<List<HubcoLocationModel>> getNearestStations({
    required double latitude,
    required double longitude,
    double? radius,
  });
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final ApiClient apiClient;

  const MapRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<HubcoLocationModel>> getNearestStations({
    required double latitude,
    required double longitude,
    double? radius,
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final url = _buildUrl(
        config.apiConstants.baseUrlLive,
        config.apiConstants.apiEndpoints.chargingStationMap,
      );

      log('[Map] Nearest stations URL: $url '
          '(lat: $latitude, long: $longitude, radius: $radius)');

      final response = await apiClient.get(
        url,
        queryParameters: {
          'latitude': latitude,
          'longitude': longitude,
          'is_nearest': true,
          'radius': radius,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is Map<String, dynamic>) {
          final stations = body['stations'];
          if (stations is List) {
            return stations
                .whereType<Map<String, dynamic>>()
                .map(HubcoLocationModel.fromNearestJson)
                .toList();
          }
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to load nearest stations',
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Joins a base URL (which may end with `/`) and an endpoint path (which may
  /// have a leading `/` or a trailing `?`) into a single clean URL.
  String _buildUrl(String baseUrl, String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    var path = endpoint.trim();
    if (path.endsWith('?')) path = path.substring(0, path.length - 1);
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
  }
}

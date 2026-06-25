import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/map/data/models/hubco_location_model.dart';
import 'package:orko_hubco/features/map/data/models/station_filter_options_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

abstract class MapRemoteDataSource {
  /// Fetches nearest charging stations around [latitude]/[longitude], optionally
  /// narrowed by the filter params, using the QA base URL and endpoint resolved
  /// from Remote Config.
  Future<List<HubcoLocationModel>> getNearestStations({
    required double latitude,
    required double longitude,
    double? radius,
    List<String>? connectorTypes,
    List<int>? amenityIds,
    double? minPrice,
    double? maxPrice,
    double? powerOutput,
  });

  /// Fetches the available filter options
  /// (`GET api/v1/charging-station/filter-options/`).
  Future<StationFilterOptionsModel> getFilterOptions();
}

class MapRemoteDataSourceImpl implements MapRemoteDataSource {
  final ApiClient apiClient;

  const MapRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<HubcoLocationModel>> getNearestStations({
    required double latitude,
    required double longitude,
    double? radius,
    List<String>? connectorTypes,
    List<int>? amenityIds,
    double? minPrice,
    double? maxPrice,
    double? powerOutput,
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

      // Only include filter params that are actually set, so an unfiltered
      // request stays `latitude/longitude/is_nearest` like before. Multi-value
      // filters (connector_type, amenity_id) are passed as LISTS so Dio emits
      // them as repeated params (`amenity_id=1&amenity_id=3`) — the backend
      // rejects a comma-joined `1,3` string with a 400.
      final queryParameters = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'is_nearest': true,
        if (radius != null) 'radius': radius,
        if (connectorTypes != null && connectorTypes.isNotEmpty)
          'connector_type': connectorTypes,
        if (amenityIds != null && amenityIds.isNotEmpty)
          'amenity_id': amenityIds,
        if (minPrice != null) 'min_price': minPrice,
        if (maxPrice != null) 'max_price': maxPrice,
        // Sent as an integer (`power_output=60`, not `60.0`).
        if (powerOutput != null) 'power_output': powerOutput.round(),
      };

      log('[Map] Nearest stations URL: $url (query: $queryParameters)');

      final response = await apiClient.get(
        url,
        queryParameters: queryParameters,
        // Repeated keys for list params, no `[]` suffix, no comma-joining.
        options: Options(listFormat: ListFormat.multi),
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

  @override
  Future<StationFilterOptionsModel> getFilterOptions() async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      // Fall back to the bundled contract path if Remote Config omits the key.
      var endpoint =
          config.apiConstants.apiEndpoints.chargingStationFilterOptions.trim();
      if (endpoint.isEmpty) {
        endpoint = 'api/v1/charging-station/filter-options/';
      }
      final url = _buildUrl(config.apiConstants.baseUrlLive, endpoint);

      log('[Map] Filter options URL: $url');

      final response = await apiClient.get(url);

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is Map) {
          return StationFilterOptionsModel.fromJson(
            Map<String, dynamic>.from(body),
          );
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to load filter options',
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

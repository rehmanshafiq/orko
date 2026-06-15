import 'dart:developer';

import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/charging/data/models/charging_station_detail_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

abstract class ChargingRemoteDataSource {
  /// Fetches the full detail for [stationId] using the QA base URL and the
  /// `charging_station_detail` endpoint resolved from Remote Config.
  Future<ChargingStationDetailModel> getStationDetail({
    required String stationId,
    required double latitude,
    required double longitude,
  });
}

class ChargingRemoteDataSourceImpl implements ChargingRemoteDataSource {
  final ApiClient apiClient;

  const ChargingRemoteDataSourceImpl({required this.apiClient});

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
        config.apiConstants.baseUrlQa,
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
}

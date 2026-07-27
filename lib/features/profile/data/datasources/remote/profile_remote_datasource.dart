import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/profile/data/models/charging_stats_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

/// Remote data source for profile operations.
abstract class ProfileRemoteDataSource {
  /// Fetches aggregated charging stats (`charging_stats` endpoint from Remote
  /// Config). Returns the parsed [ChargingStatsModel] (`body`).
  /// Throws [ServerException] on failure.
  Future<ChargingStatsModel> getChargingStats();
}

class ProfileRemoteDataSourceImpl implements ProfileRemoteDataSource {
  final ApiClient apiClient;

  const ProfileRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ChargingStatsModel> getChargingStats() async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.chargingStats;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Charging stats are not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      AppLogger.d('[Profile] Charging stats URL: $url');

      final response = await apiClient.get(url);

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is Map) {
          return ChargingStatsModel.fromJson(Map<String, dynamic>.from(body));
        }
        // A success envelope with an empty/missing body → zeroed stats.
        return const ChargingStatsModel();
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to load charging stats',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : (e.message ?? 'Failed to load charging stats'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Joins base + endpoint, preserving the trailing slash (Django routes).
  String _buildUrl(String baseUrl, String endpoint) {
    final base = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    var path = endpoint.trim();
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
  }
}

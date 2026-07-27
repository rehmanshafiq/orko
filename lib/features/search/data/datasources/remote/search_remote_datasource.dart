import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/core/utils/app_logger.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/search/data/models/station_result_model.dart';

abstract class SearchRemoteDataSource {
  /// Searches charging stations matching [query] around [latitude]/[longitude]
  /// (`POST api/v1/charging-station/search/?latitude=..&longitude=..`).
  Future<List<StationResultModel>> searchStations({
    required String query,
    required double latitude,
    required double longitude,
  });

  /// Fetches popular charging stations around [latitude]/[longitude]
  /// (`GET api/v1/charging-station/popular/?latitude=..&longitude=..`).
  Future<List<StationResultModel>> getPopularStations({
    required double latitude,
    required double longitude,
  });
}

class SearchRemoteDataSourceImpl implements SearchRemoteDataSource {
  final ApiClient apiClient;

  const SearchRemoteDataSourceImpl({required this.apiClient});

  static const String _defaultSearchPath = 'api/v1/charging-station/search/';
  static const String _defaultPopularPath = 'api/v1/charging-station/popular/';

  @override
  Future<List<StationResultModel>> searchStations({
    required String query,
    required double latitude,
    required double longitude,
  }) {
    return _guard('search', () async {
      final url = _endpointUrl(
        (e) => e.chargingStationSearch,
        fallbackPath: _defaultSearchPath,
      );
      // Coordinates and the raw query are PII — never logged.
      AppLogger.d('[Search] Search request', name: 'Search');

      final response = await apiClient.post(
        url,
        // latitude/longitude go on the query string per the API contract;
        // the search term goes in the JSON body.
        queryParameters: {'latitude': latitude, 'longitude': longitude},
        data: {'query': query},
      );

      final body = _bodyOf(response, fallback: 'Failed to search stations');
      // Search wraps results in `body.stations`; be lenient if it's a bare list.
      final stations = body is Map ? body['stations'] : body;
      if (stations is! List) return const <StationResultModel>[];
      return stations
          .whereType<Map>()
          .map((e) =>
              StationResultModel.fromSearchJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  @override
  Future<List<StationResultModel>> getPopularStations({
    required double latitude,
    required double longitude,
  }) {
    return _guard('popular', () async {
      final url = _endpointUrl(
        (e) => e.chargingStationPopular,
        fallbackPath: _defaultPopularPath,
      );
      // Coordinates are PII — never logged.
      AppLogger.d('[Search] Popular request', name: 'Search');

      final response = await apiClient.get(
        url,
        queryParameters: {'latitude': latitude, 'longitude': longitude},
      );

      final body =
          _bodyOf(response, fallback: 'Failed to load popular stations');
      // Popular returns `body` as a bare list of stations.
      if (body is! List) return const <StationResultModel>[];
      return body
          .whereType<Map>()
          .map((e) =>
              StationResultModel.fromPopularJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Normalises every error into a [ServerException] carrying the backend's
  /// `message` when present, so validation strings reach the UI verbatim.
  Future<T> _guard<T>(String tag, Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      final code = e.response?.statusCode;
      final backendMessage = (data is Map && data['message'] != null)
          ? data['message'].toString().trim()
          : '';
      final String message;
      if (backendMessage.isNotEmpty) {
        message = backendMessage;
      } else if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout) {
        message = 'The request timed out. Please try again.';
      } else {
        message = _friendlyStatusMessage(code);
      }
      AppLogger.d('[Search] $tag failed ($code): ${e.message}', name: 'Search');
      throw ServerException(message: message, statusCode: code, originalError: e);
    } catch (e) {
      AppLogger.d('[Search] $tag unexpected error: $e', name: 'Search');
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  String _friendlyStatusMessage(int? code) {
    switch (code) {
      case 401:
        return 'Your session has expired. Please log in again.';
      case 403:
        return 'You do not have permission to do that.';
      case 404:
      case 405:
        return 'This action is not available right now.';
      case 500:
      case 502:
      case 503:
        return 'The server is having trouble. Please try again shortly.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }

  String _endpointUrl(
    String Function(dynamic endpoints) select, {
    required String fallbackPath,
  }) {
    final config = RemoteConfigService.config;
    if (config == null) {
      throw const ServerException(message: 'Remote config not initialized');
    }
    var endpoint = select(config.apiConstants.apiEndpoints).toString().trim();
    if (endpoint.isEmpty) endpoint = fallbackPath;
    return _buildUrl(ApiClient.baseUrl, endpoint);
  }

  /// Validates the `{status, body}` envelope and returns `body`.
  dynamic _bodyOf(Response response, {required String fallback}) {
    final data = response.data;
    if (response.statusCode == 200 && data is Map<String, dynamic>) {
      if (data.containsKey('body')) return data['body'];
    }
    throw ServerException(
      message: (data is Map && data['message'] != null)
          ? data['message'].toString()
          : fallback,
      statusCode: response.statusCode,
    );
  }

  /// Joins base + endpoint, PRESERVING the trailing slash (Django routes need
  /// it — without it the server 301-redirects and drops the POST body).
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

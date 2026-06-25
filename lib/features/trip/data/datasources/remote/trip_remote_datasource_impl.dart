import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/trip/data/datasources/remote/trip_remote_datasource.dart';
import 'package:orko_hubco/features/trip/data/models/saved_trip_model.dart';
import 'package:orko_hubco/features/trip/data/models/trip_plan_result_model.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';

class TripRemoteDataSourceImpl implements TripRemoteDataSource {
  final ApiClient apiClient;

  const TripRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<TripPlanResultModel> planTrip(TripPlanParams params) async {
    return _guard('plan-trip', () async {
      final url = _endpointUrl(
        (e) => e.planTrip,
        fallbackPath: 'api/v1/trip-planning/plan-trip/',
        unavailableMessage: 'Trip planning is not available right now',
      );
      log('[Trip] Plan URL: $url');

      final response = await apiClient.post(url, data: params.toJson());
      final body = _bodyOf(response, fallback: 'Failed to plan trip');
      if (body is! Map) {
        throw const ServerException(message: 'Failed to plan trip');
      }
      return TripPlanResultModel.fromJson(
        Map<String, dynamic>.from(body),
        message: _envelopeMessage(response),
      );
    });
  }

  @override
  Future<SavedTripModel> saveTrip(TripPlanParams params) async {
    return _guard('save-trip', () async {
      final url = _endpointUrl(
        (e) => e.saveTrip,
        fallbackPath: 'api/v1/trip-planning/save-trip/',
        unavailableMessage: 'Saving a trip is not available right now',
      );
      log('[Trip] Save URL: $url');

      final response = await apiClient.post(url, data: params.toJson());
      final body = _bodyOf(response, fallback: 'Failed to save trip');
      if (body is! Map) {
        throw const ServerException(message: 'Failed to save trip');
      }
      return SavedTripModel.fromJson(Map<String, dynamic>.from(body));
    });
  }

  @override
  Future<List<SavedTripModel>> getSavedTrips() async {
    return _guard('saved-trips', () async {
      final url = _endpointUrl(
        (e) => e.savedTrips,
        fallbackPath: 'api/v1/trip-planning/trips/',
        unavailableMessage: 'Your saved trips are not available right now',
      );
      log('[Trip] Saved trips URL: $url');

      final response = await apiClient.get(url);
      final body = _bodyOf(response, fallback: 'Failed to load saved trips');
      // The list may arrive bare or wrapped in a paginated { results: [...] }.
      final list = body is Map ? body['results'] : body;
      if (list is! List) return const <SavedTripModel>[];
      return list
          .whereType<Map>()
          .map((e) => SavedTripModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  @override
  Future<SavedTripModel> getSavedTripDetail(int id) async {
    return _guard('saved-trip-detail', () async {
      // `saved_trip_detail` is the `trips/` base; the id segment is appended.
      final url = _endpointUrl(
        (e) => '${e.savedTripDetail}$id/',
        fallbackPath: 'api/v1/trip-planning/trips/$id/',
        unavailableMessage: 'This trip is not available right now',
      );
      log('[Trip] Saved trip detail URL: $url');

      final response = await apiClient.get(url);
      final body = _bodyOf(response, fallback: 'Trip plan not found.');
      if (body is! Map) {
        throw const ServerException(message: 'Trip plan not found.');
      }
      return SavedTripModel.fromJson(Map<String, dynamic>.from(body));
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Normalises every error into a [ServerException] carrying the backend's
  /// `message` (so 400/422 validation strings reach the UI verbatim).
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
      log('[Trip] $tag failed ($code): ${e.message}');
      throw ServerException(message: message, statusCode: code, originalError: e);
    } catch (e) {
      log('[Trip] $tag unexpected error: $e');
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
    String Function(ApiEndpoints endpoints) select, {
    required String fallbackPath,
    required String unavailableMessage,
  }) {
    final config = RemoteConfigService.config;
    if (config == null) {
      throw const ServerException(message: 'Remote config not initialized');
    }
    var endpoint = select(config.apiConstants.apiEndpoints).trim();
    if (endpoint.isEmpty) endpoint = fallbackPath;
    if (endpoint.isEmpty) {
      throw ServerException(message: unavailableMessage);
    }
    return _buildUrl(config.apiConstants.baseUrlLive, endpoint);
  }

  /// Validates the `{status, message, body}` envelope and returns `body`.
  /// Accepts 200 and 201 (POST plan/save may return either).
  dynamic _bodyOf(Response response, {required String fallback}) {
    final data = response.data;
    final code = response.statusCode;
    if ((code == 200 || code == 201) && data is Map<String, dynamic>) {
      if (data.containsKey('body')) return data['body'];
    }
    throw ServerException(
      message: (data is Map && data['message'] != null)
          ? data['message'].toString()
          : fallback,
      statusCode: code,
    );
  }

  /// The envelope-level `message` (used to surface the feasible:false warning).
  String? _envelopeMessage(Response response) {
    final data = response.data;
    if (data is Map && data['message'] != null) {
      final m = data['message'].toString().trim();
      return m.isEmpty ? null : m;
    }
    return null;
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

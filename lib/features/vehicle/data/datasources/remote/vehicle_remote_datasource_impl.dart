import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/vehicle/data/datasources/remote/vehicle_remote_datasource.dart';
import 'package:orko_hubco/features/vehicle/data/models/created_vehicle_model.dart';
import 'package:orko_hubco/features/vehicle/data/models/user_vehicle_model.dart';
import 'package:orko_hubco/features/vehicle/data/models/vehicle_make_model.dart';
import 'package:orko_hubco/features/vehicle/data/models/vehicle_model_model.dart';

class VehicleRemoteDataSourceImpl implements VehicleRemoteDataSource {
  final ApiClient apiClient;

  const VehicleRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<VehicleMakeModel>> getMakes() async {
    return _guard('makes', () async {
      final url = _endpointUrl(
        (e) => e.vehicleMakes,
        fallbackPath: 'api/v1/vehicle/makes/',
        unavailableMessage: 'Vehicle makes are not available right now',
      );
      log('[Vehicle] Makes URL: $url');

      final response = await apiClient.get(url);
      final results = _resultsOf(response, fallback: 'Failed to load makes');
      return results
          .map((e) => VehicleMakeModel.fromJson(e))
          .toList(growable: false);
    });
  }

  @override
  Future<List<VehicleModelModel>> getModels({required int makeId}) async {
    return _guard('models', () async {
      final url = _endpointUrl(
        (e) => e.vehicleModels,
        fallbackPath: 'api/v1/vehicle/models/',
        unavailableMessage: 'Vehicle models are not available right now',
      );
      log('[Vehicle] Models URL: $url (md_make__id: $makeId)');

      final response = await apiClient.get(
        url,
        queryParameters: {'md_make__id': makeId},
      );
      final results = _resultsOf(response, fallback: 'Failed to load models');
      return results
          .map((e) => VehicleModelModel.fromJson(e))
          .toList(growable: false);
    });
  }

  @override
  Future<CreatedVehicleModel> addVehicle({
    required int mdMake,
    required int mdModel,
    required String year,
    String? vehicleRfid,
  }) async {
    return _guard('add-vehicle', () async {
      final url = _endpointUrl(
        (e) => e.addVehicle,
        fallbackPath: 'api/v1/vehicle/add-vehicle/',
        unavailableMessage: 'Adding a vehicle is not available right now',
      );
      log('[Vehicle] Add URL: $url (make: $mdMake, model: $mdModel)');

      final response = await apiClient.post(
        url,
        data: {
          'md_make': mdMake,
          'md_model': mdModel,
          'year': year,
          if (vehicleRfid != null && vehicleRfid.isNotEmpty)
            'vehicle_rfid': vehicleRfid,
        },
      );

      final body = _bodyOf(response, fallback: 'Failed to add vehicle');
      if (body is Map) {
        return CreatedVehicleModel.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(message: 'Failed to add vehicle');
    });
  }

  @override
  Future<List<UserVehicleModel>> getUserVehicles() async {
    return _guard('user-vehicles', () async {
      final url = _endpointUrl(
        (e) => e.userVehicles,
        fallbackPath: 'api/v1/vehicle/user-vehicle/',
        unavailableMessage: 'Your vehicles are not available right now',
      );
      log('[Vehicle] User vehicles URL: $url');

      final response = await apiClient.get(url);
      final body = _bodyOf(response, fallback: 'Failed to load your vehicles');
      if (body is! List) {
        // A successful response with no vehicles is a valid empty list.
        return const <UserVehicleModel>[];
      }
      return body
          .whereType<Map>()
          .map((e) => UserVehicleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  @override
  Future<void> deleteVehicle({required int id}) async {
    return _guard('delete-vehicle', () async {
      final url = _endpointUrl(
        (e) => e.deleteVehicle,
        fallbackPath: 'api/v1/vehicle/add-vehicle/',
        unavailableMessage: 'Deleting a vehicle is not available right now',
      );
      log('[Vehicle] Delete URL: $url (id: $id)');

      // Soft-delete shares the add-vehicle path; the id goes in the JSON body
      // per the API contract.
      final response = await apiClient.delete(url, data: {'id': id});

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return;

      final data = response.data;
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to delete vehicle',
        statusCode: response.statusCode,
      );
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
      // Prefer the backend's own message; otherwise a clean, status-appropriate
      // string — never Dio's raw validateStatus paragraph.
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
      log('[Vehicle] $tag failed ($code): ${e.message}');
      throw ServerException(message: message, statusCode: code, originalError: e);
    } catch (e) {
      log('[Vehicle] $tag unexpected error: $e');
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// A clean, user-facing message for a status code when the backend didn't
  /// provide one (keeps Dio's verbose validateStatus text out of the UI).
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
    // Fall back to the bundled contract path when Remote Config (e.g. a stale
    // Firebase parameter) doesn't yet provide the key.
    var endpoint = select(config.apiConstants.apiEndpoints).trim();
    if (endpoint.isEmpty) endpoint = fallbackPath;
    if (endpoint.isEmpty) {
      throw ServerException(message: unavailableMessage);
    }
    return _buildUrl(config.apiConstants.baseUrlLive, endpoint);
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

  /// Extracts the `body.results` list (paginated shape) as a list of maps.
  List<Map<String, dynamic>> _resultsOf(
    Response response, {
    required String fallback,
  }) {
    final body = _bodyOf(response, fallback: fallback);
    // Paginated: { count, results: [...] }. Be lenient if `body` is itself a list.
    final results = body is Map ? body['results'] : body;
    if (results is! List) return const [];
    return results
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList(growable: false);
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

import 'package:orko_hubco/core/utils/app_logger.dart';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/support/data/models/support_category_model.dart';
import 'package:orko_hubco/features/support/data/models/support_ticket_model.dart';

/// Remote data source for support tickets (`cvp_support_ticket` endpoint).
abstract class SupportRemoteDataSource {
  /// Fetches the available ticket categories (`cvp_support_ticket_categories`).
  /// Throws [ServerException] on failure.
  Future<List<SupportCategoryModel>> getCategories();

  /// Creates a support ticket via multipart POST. [category] is the backend DB
  /// value (snake_case). [attachmentPaths] are local image paths (already
  /// validated for type/size/count by the caller). Throws [ServerException].
  Future<SupportTicketModel> createTicket({
    required String category,
    required String description,
    List<String> attachmentPaths,
  });
}

class SupportRemoteDataSourceImpl implements SupportRemoteDataSource {
  final ApiClient apiClient;

  const SupportRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<List<SupportCategoryModel>> getCategories() async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint =
          config.apiConstants.apiEndpoints.cvpSupportTicketCategories;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Support categories are not available right now',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      AppLogger.d('[Support] Categories URL: $url');

      final response = await apiClient.get(url);

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is List) {
          return body
              .whereType<Map>()
              .map((e) =>
                  SupportCategoryModel.fromJson(Map<String, dynamic>.from(e)))
              .where((c) => c.value.isNotEmpty)
              .toList();
        }
      }

      throw ServerException(
        message: (data is Map<String, dynamic> && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to load categories',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Failed to load categories'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<SupportTicketModel> createTicket({
    required String category,
    required String description,
    List<String> attachmentPaths = const [],
  }) async {
    try {
      final config = RemoteConfigService.config;
      if (config == null) {
        throw const ServerException(message: 'Remote config not initialized');
      }

      final endpoint = config.apiConstants.apiEndpoints.cvpSupportTicket;
      if (endpoint.trim().isEmpty) {
        throw const ServerException(
          message: 'Support is not available right now. Please try again later.',
        );
      }

      final url = _buildUrl(ApiClient.baseUrl, endpoint);
      AppLogger.d('[Support] Create-ticket URL: $url');

      // The backend accepts repeated `attachments` parts under one field name.
      final attachments = <MultipartFile>[];
      for (final path in attachmentPaths) {
        final fileName = path.split('/').last;
        final ext =
            fileName.contains('.') ? fileName.split('.').last.toLowerCase() : 'jpg';
        final subtype = ext == 'png' ? 'png' : 'jpeg';
        final safeName = fileName.contains('.') ? fileName : '$fileName.jpg';
        attachments.add(
          await MultipartFile.fromFile(
            path,
            filename: safeName,
            contentType: DioMediaType('image', subtype),
          ),
        );
      }

      final formData = FormData.fromMap({
        'category': category,
        'description': description,
        if (attachments.isNotEmpty) 'attachments': attachments,
      });

      // Pass FormData straight through so Dio sets the multipart boundary.
      final response = await apiClient.post(url, data: formData);

      final data = response.data;
      final isOk =
          (response.statusCode == 200 || response.statusCode == 201) &&
              (data is! Map ||
                  data['status'] == null ||
                  data['status'] == 200 ||
                  data['status'] == 201);

      if (isOk) {
        final body = data is Map ? data['body'] : null;
        if (body is Map) {
          return SupportTicketModel.fromJson(Map<String, dynamic>.from(body));
        }
        // Success envelope without a parseable body — still a success.
        return const SupportTicketModel(referenceCode: '');
      }

      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Failed to submit your request',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw ServerException(
        message: _dioMessage(e, fallback: 'Failed to submit your request'),
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Extracts a human-readable message from a Dio error, preferring the
  /// backend's `message`/field errors over the raw transport message.
  String _dioMessage(DioException e, {required String fallback}) {
    final data = e.response?.data;
    if (data is Map) {
      if (data['message'] != null) return data['message'].toString();
      // DRF field errors, e.g. {"category": ["Invalid choice."]}.
      final errors = data['errors'] ?? data['body'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) return first.first.toString();
        return first.toString();
      }
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return 'The request timed out. Please try again.';
    }
    return e.message ?? fallback;
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

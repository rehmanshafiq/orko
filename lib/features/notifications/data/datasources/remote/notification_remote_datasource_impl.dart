import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/notifications/data/datasources/remote/notification_remote_datasource.dart';
import 'package:orko_hubco/features/notifications/data/models/notification_page_model.dart';
import 'package:orko_hubco/features/notifications/data/models/notification_preferences_model.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

class NotificationRemoteDataSourceImpl implements NotificationRemoteDataSource {
  final ApiClient apiClient;

  const NotificationRemoteDataSourceImpl({required this.apiClient});

  // Fallback paths used when Remote Config doesn't provide the endpoint.
  static const String _listFallback = 'api/v1/notifications/';
  static const String _unreadCountFallback =
      'api/v1/notifications/unread-count/';
  static const String _markAllReadFallback =
      'api/v1/notifications/mark-all-read/';
  static const String _preferencesFallback =
      'api/v1/notifications/preferences/';
  static const String _deviceTokenFallback =
      'api/v1/notifications/device-token/';

  @override
  Future<NotificationPageModel> getNotifications({
    required int page,
    required int pageSize,
  }) async {
    return _guard('list', () async {
      final url = _resolveUrl(_listPath());
      log('[Notifications] List URL: $url (page $page)');

      final response = await apiClient.get(
        url,
        queryParameters: {'page': page, 'page_size': pageSize},
      );
      _ensureOk(response, fallback: 'Failed to load notifications');
      return NotificationPageModel.fromResponse(
        response.data,
        requestedPageSize: pageSize,
      );
    });
  }

  @override
  Future<int> getUnreadCount() async {
    return _guard('unread-count', () async {
      final url = _resolveUrl(
        _endpoint((e) => e.notificationsUnreadCount, _unreadCountFallback),
      );
      log('[Notifications] Unread-count URL: $url');

      final response = await apiClient.get(url);
      _ensureOk(response, fallback: 'Failed to load unread count');
      return _extractUnreadCount(response.data);
    });
  }

  @override
  Future<bool> markRead(int id) async {
    return _guard('mark-read', () async {
      // `<base>/<id>/mark-read/` — the id segment sits inside the list base.
      var base = _listPath();
      if (!base.endsWith('/')) base = '$base/';
      final url = _resolveUrl('$base$id/mark-read/');
      log('[Notifications] Mark-read URL: $url');

      final response = await apiClient.post(url);
      _ensureOk(response, fallback: 'Failed to mark notification read');
      return true;
    });
  }

  @override
  Future<bool> markAllRead() async {
    return _guard('mark-all-read', () async {
      final url = _resolveUrl(
        _endpoint((e) => e.notificationsMarkAllRead, _markAllReadFallback),
      );
      log('[Notifications] Mark-all-read URL: $url');

      final response = await apiClient.post(url);
      _ensureOk(response, fallback: 'Failed to mark all notifications read');
      return true;
    });
  }

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    return _guard('preferences-get', () async {
      final url = _resolveUrl(
        _endpoint((e) => e.notificationsPreferences, _preferencesFallback),
      );
      log('[Notifications] Preferences GET URL: $url');

      final response = await apiClient.get(url);
      _ensureOk(response, fallback: 'Failed to load notification preferences');
      return _parsePreferences(response.data);
    });
  }

  @override
  Future<NotificationPreferencesModel> updatePreferences(
    Map<String, bool> changes,
  ) async {
    return _guard('preferences-patch', () async {
      final url = _resolveUrl(
        _endpoint((e) => e.notificationsPreferences, _preferencesFallback),
      );
      log('[Notifications] Preferences PATCH URL: $url body: $changes');

      final response = await apiClient.patch(url, data: changes);
      _ensureOk(response, fallback: 'Failed to update notification preferences');
      return _parsePreferences(response.data);
    });
  }

  @override
  Future<bool> registerDeviceToken(String token) async {
    return _guard('device-token-register', () async {
      final url = _resolveUrl(
        _endpoint((e) => e.notificationsDeviceToken, _deviceTokenFallback),
      );
      log('[Notifications] Device-token POST URL: $url');

      final response = await apiClient.post(url, data: {'token': token});
      _ensureOk(response, fallback: 'Failed to register device token');
      return true;
    });
  }

  @override
  Future<bool> deleteDeviceToken() async {
    return _guard('device-token-delete', () async {
      final url = _resolveUrl(
        _endpoint((e) => e.notificationsDeviceToken, _deviceTokenFallback),
      );
      log('[Notifications] Device-token DELETE URL: $url');

      final response = await apiClient.delete(url);
      _ensureOk(response, fallback: 'Failed to clear device token');
      return true;
    });
  }

  NotificationPreferencesModel _parsePreferences(dynamic data) {
    if (data is! Map) {
      throw const ServerException(
        message: 'Failed to read notification preferences',
      );
    }
    return NotificationPreferencesModel.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// The notifications list base path (also the root for `mark-read`).
  String _listPath() => _endpoint((e) => e.notifications, _listFallback);

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Normalises every error into a [ServerException] carrying the backend's
  /// `message` (so 4xx validation strings reach the UI verbatim).
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
      log('[Notifications] $tag failed ($code): ${e.message}');
      throw ServerException(message: message, statusCode: code, originalError: e);
    } catch (e) {
      log('[Notifications] $tag unexpected error: $e');
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

  /// Throws a [ServerException] for any non-2xx status, surfacing the backend
  /// `message` when present.
  void _ensureOk(Response response, {required String fallback}) {
    final code = response.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final data = response.data;
    throw ServerException(
      message: (data is Map && data['message'] != null)
          ? data['message'].toString()
          : fallback,
      statusCode: code,
    );
  }

  /// Reads `unread_count` from a bare body or a `body`-wrapped envelope.
  int _extractUnreadCount(dynamic data) {
    var payload = data;
    if (payload is Map && payload['body'] != null) {
      payload = payload['body'];
    }
    if (payload is Map) {
      final raw = payload['unread_count'];
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? 0;
    }
    return 0;
  }

  /// Reads an endpoint path from Remote Config, falling back to [fallback]
  /// when the config is missing or the value is blank.
  String _endpoint(
    String Function(ApiEndpoints endpoints) select,
    String fallback,
  ) {
    final endpoints = RemoteConfigService.config?.apiConstants.apiEndpoints;
    final value = endpoints == null ? '' : select(endpoints).trim();
    return value.isEmpty ? fallback : value;
  }

  /// Joins the remote-config QA base with [path], preserving the trailing slash
  /// Django routes require.
  String _resolveUrl(String path) {
    final config = RemoteConfigService.config;
    final base = (config?.apiConstants.baseUrlLive.trim().isNotEmpty ?? false)
        ? config!.apiConstants.baseUrlLive.trim()
        : 'https://staging-python.orkofleet.com/';
    final cleanBase = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
    final cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$cleanBase/$cleanPath';
  }
}

import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/booking/data/datasources/remote/booking_remote_datasource.dart';
import 'package:orko_hubco/features/booking/data/models/booking_model.dart';
import 'package:orko_hubco/features/booking/data/models/booking_slot_model.dart';
import 'package:orko_hubco/features/booking/data/models/charge_session_detail_model.dart';
import 'package:orko_hubco/features/booking/data/models/charge_session_history_model.dart';
import 'package:orko_hubco/features/booking/data/models/charger_details_model.dart';
import 'package:orko_hubco/features/booking/data/models/live_session_model.dart';
import 'package:orko_hubco/features/booking/data/models/my_booking_model.dart';
import 'package:orko_hubco/features/booking/data/models/verify_qr_model.dart';
import 'package:orko_hubco/features/remote_config/data/models/remote_config_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

class BookingRemoteDataSourceImpl implements BookingRemoteDataSource {
  final ApiClient apiClient;

  const BookingRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ChargerDetailsModel> getChargerDetails({
    required int locationId,
  }) async {
    return _guard('charger-details', () async {
      final url = _endpointUrl(
        (e) => e.chargerDetails,
        unavailableMessage: 'Charger details are not available right now',
      );
      log('[Booking] Charger details URL: $url (location_id: $locationId)');

      final response = await apiClient.get(
        url,
        queryParameters: {'location_id': locationId},
      );

      final body = _bodyOf(response, fallback: 'Failed to load charger details');
      if (body is Map) {
        return ChargerDetailsModel.fromJson(Map<String, dynamic>.from(body));
      }
      throw const ServerException(message: 'Failed to load charger details');
    });
  }

  @override
  Future<List<BookingSlotModel>> getSlots({
    required String date,
    required int locationId,
  }) async {
    return _guard('slots', () async {
      final url = _endpointUrl(
        (e) => e.bookingSlots,
        unavailableMessage: 'Time slots are not available right now',
      );
      log('[Booking] Slots URL: $url (date: $date, location_id: $locationId)');

      final response = await apiClient.get(
        url,
        queryParameters: {'date': date, 'location_id': locationId},
      );

      final body = _bodyOf(response, fallback: 'Failed to load time slots');
      if (body is! List) {
        throw const ServerException(message: 'Failed to load time slots');
      }
      return body
          .whereType<Map>()
          .map((e) => BookingSlotModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  @override
  Future<BookingModel> createBooking({
    required String bookingDate,
    required String startTime,
    required String endTime,
    required int location,
  }) async {
    return _guard('create-booking', () async {
      final url = _endpointUrl(
        (e) => e.createBooking,
        unavailableMessage: 'Booking is not available right now',
      );
      log('[Booking] Create URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'booking_date': bookingDate,
          'start_time': startTime,
          'end_time': endTime,
          'location': location,
        },
      );
      return _bookingFromResponse(response, fallback: 'Booking failed');
    });
  }

  @override
  Future<BookingModel> createBookingHgl({
    required String bookingDate,
    required String startTime,
    required int location,
    int? vehicleId,
    int noOfSlots = 1,
  }) async {
    return _guard('create-booking-hgl', () async {
      final url = _endpointUrl(
        (e) => e.createBookingHgl,
        unavailableMessage: 'Booking is not available right now',
      );
      log('[Booking] Create (HGL) URL: $url');

      final response = await apiClient.post(
        url,
        data: {
          'booking_date': bookingDate,
          'start_time': startTime,
          'location': location,
          if (vehicleId != null) 'vehicle_id': vehicleId,
          // 1 = 30 min (server default), 2 = 1 hour on consecutive slots.
          if (noOfSlots > 1) 'no_of_slots': noOfSlots,
        },
      );
      return _bookingFromResponse(response, fallback: 'Booking failed');
    });
  }

  @override
  Future<List<MyBookingModel>> getMyBookings() async {
    return _guard('my-bookings', () async {
      final url = _endpointUrl(
        (e) => e.myBookings,
        unavailableMessage: 'Bookings are not available right now',
      );
      log('[Booking] My bookings URL: $url');

      final response = await apiClient.get(url);

      final body = _bodyOf(response, fallback: 'Failed to load bookings');
      if (body is! List) {
        throw const ServerException(message: 'Failed to load bookings');
      }
      return body
          .whereType<Map>()
          .map((e) => MyBookingModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  @override
  Future<List<ChargeSessionHistoryModel>> getChargeSessionHistory() async {
    return _guard('charge-session-history', () async {
      final url = _endpointUrl(
        (e) => e.chargeSessionHistory,
        unavailableMessage: 'Charging history is not available right now',
      );
      log('[Booking] Charge session history URL: $url');

      final response = await apiClient.get(url);

      final body = _bodyOf(response, fallback: 'Failed to load charging history');
      if (body is! List) {
        throw const ServerException(
          message: 'Failed to load charging history',
        );
      }
      return body
          .whereType<Map>()
          .map((e) =>
              ChargeSessionHistoryModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(growable: false);
    });
  }

  @override
  Future<LiveSessionModel> getLiveSession() async {
    return _guard('live-session', () async {
      final url = _endpointUrl(
        (e) => e.liveSession,
        unavailableMessage: 'Live session is not available right now',
      );
      log('[Booking] Live session URL: $url');

      final response = await apiClient.get(url);

      final body = _bodyOf(response, fallback: 'Failed to load live session');
      if (body is Map) {
        return LiveSessionModel.fromJson(Map<String, dynamic>.from(body));
      }
      // A well-formed success must carry the `{active: ...}` object; anything
      // else means no session is running.
      return const LiveSessionModel(active: false);
    });
  }

  @override
  Future<ChargeSessionDetailModel> getChargeSessionDetails({
    required int sessionId,
  }) async {
    return _guard('charge-session-details', () async {
      final url = _endpointUrl(
        (e) => e.chargeSessionDetails,
        unavailableMessage: 'Session details are not available right now',
      );
      log('[Booking] Charge session details URL: $url (id: $sessionId)');

      final response = await apiClient.get(
        url,
        queryParameters: {'id': sessionId},
      );

      final body = _bodyOf(response, fallback: 'Failed to load session details');
      if (body is Map && body.isNotEmpty) {
        return ChargeSessionDetailModel.fromJson(
          Map<String, dynamic>.from(body),
        );
      }
      throw const ServerException(message: 'Failed to load session details');
    });
  }

  @override
  Future<String> getReceiptUrl({required int sessionId}) async {
    return _guard('download-receipt', () async {
      // The session id is a trailing path segment (endpoint keeps its slash),
      // e.g. `.../download-receipt/17058`.
      final url = _endpointUrl(
        (e) => e.downloadReceipt,
        unavailableMessage: 'Receipt download is not available right now',
      );
      final receiptEndpoint = '$url$sessionId';
      log('[Booking] Download receipt URL: $receiptEndpoint');

      final response = await apiClient.get(receiptEndpoint);

      final body = _bodyOf(response, fallback: 'Failed to generate receipt');
      if (body is Map) {
        final receiptUrl = body['receipt_url'];
        if (receiptUrl is String && receiptUrl.trim().isNotEmpty) {
          return receiptUrl.trim();
        }
      }
      throw const ServerException(
        message: 'Receipt is not ready yet. Please try again later.',
      );
    });
  }

  @override
  Future<String> cancelBooking({required int bookingId}) async {
    return _guard('cancel-booking', () async {
      final url = _endpointUrl(
        (e) => e.cancelBooking,
        unavailableMessage: 'Cancellation is not available right now',
      );
      log('[Booking] Cancel URL: $url (booking_id: $bookingId)');

      final response = await apiClient.post(
        url,
        data: {'booking_id': bookingId},
      );

      final body = _bodyOf(response, fallback: 'Failed to cancel booking');
      if (body is Map && body['data'] != null) {
        return body['data'].toString();
      }
      return 'Your booking is cancelled.';
    });
  }

  @override
  Future<BookingModel> rescheduleBooking({
    required int bookingId,
    required String bookingDate,
    required String startTime,
    required int location,
    int noOfSlots = 1,
  }) async {
    return _guard('reschedule-booking', () async {
      final url = _endpointUrl(
        (e) => e.rescheduleBooking,
        unavailableMessage: 'Rescheduling is not available right now',
      );
      log('[Booking] Reschedule URL: $url (booking_id: $bookingId)');

      // end_time is auto-derived by the backend (start + 30 × no_of_slots min).
      // Sending it triggers a server-side failure, so it must NOT be included.
      final response = await apiClient.post(
        url,
        data: {
          'booking_id': bookingId,
          'booking_date': bookingDate,
          'start_time': startTime,
          'location': location,
          // 1 = 30 min (server default), 2 = 1 hour on consecutive slots.
          if (noOfSlots > 1) 'no_of_slots': noOfSlots,
        },
      );
      return _bookingFromResponse(response, fallback: 'Rescheduling failed');
    });
  }

  @override
  Future<VerifyQrModel> verifyQr({
    required String bookingCode,
    required String chargePointId,
    required int connectorId,
  }) async {
    return _guard('verify-qr', () async {
      final url = _endpointUrl(
        (e) => e.verifyQr,
        unavailableMessage: 'QR verification is not available right now',
      );
      log('[Booking] Verify QR URL: $url '
          '(booking_code: $bookingCode, charge_point_id: $chargePointId, '
          'connector_id: $connectorId)');

      // A wrong connector legitimately comes back as 422 with a meaningful
      // `{is_match: false, ...}` body — treat it as a result, not an error, by
      // letting both 200 and 422 through Dio's status validation.
      final response = await apiClient.post(
        url,
        data: {
          'booking_code': bookingCode,
          'charge_point_id': chargePointId,
          'connector_id': connectorId,
        },
        options: Options(
          validateStatus: (status) => status == 200 || status == 422,
        ),
      );

      final data = response.data;
      if (data is Map<String, dynamic> && data['body'] is Map) {
        return VerifyQrModel.fromEnvelope(data);
      }
      // A 200/422 without the expected envelope: surface the backend message
      // if present, else a generic failure.
      throw ServerException(
        message: (data is Map && data['message'] != null)
            ? data['message'].toString()
            : 'Could not verify the QR code',
        statusCode: response.statusCode,
      );
    });
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  /// Runs [action], normalising every error into a [ServerException] that
  /// carries the backend's `message` (e.g. the 422 validation strings) so the
  /// UI can show exactly what the API said.
  Future<T> _guard<T>(String tag, Future<T> Function() action) async {
    try {
      return await action();
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (e.type == DioExceptionType.connectionTimeout ||
                  e.type == DioExceptionType.receiveTimeout ||
                  e.type == DioExceptionType.sendTimeout
              ? 'The request timed out. Please try again.'
              : (e.message ?? 'Something went wrong'));
      log('[Booking] $tag failed (${e.response?.statusCode}): $message');
      throw ServerException(
        message: message,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      log('[Booking] $tag unexpected error: $e');
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Resolves and builds a full endpoint URL from Remote Config, throwing a
  /// friendly [ServerException] when config is missing or the endpoint is blank.
  String _endpointUrl(
    String Function(ApiEndpoints endpoints) select, {
    required String unavailableMessage,
  }) {
    final config = RemoteConfigService.config;
    if (config == null) {
      throw const ServerException(message: 'Remote config not initialized');
    }
    final endpoint = select(config.apiConstants.apiEndpoints);
    if (endpoint.trim().isEmpty) {
      throw ServerException(message: unavailableMessage);
    }
    return _buildUrl(ApiClient.baseUrl, endpoint);
  }

  /// Validates the `{status, body}` envelope and returns `body`, throwing the
  /// backend message when the response shape isn't a success.
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

  BookingModel _bookingFromResponse(
    Response response, {
    required String fallback,
  }) {
    final body = _bodyOf(response, fallback: fallback);
    if (body is Map) {
      return BookingModel.fromJson(Map<String, dynamic>.from(body));
    }
    throw ServerException(message: fallback, statusCode: response.statusCode);
  }

  /// Joins base + endpoint, PRESERVING the trailing slash. The booking
  /// endpoints are Django routes that require the trailing slash — without it
  /// the server 301-redirects the request and the POST body is dropped (→ 500).
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

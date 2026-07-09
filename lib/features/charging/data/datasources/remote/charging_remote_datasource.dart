import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/network/api_client.dart';
import 'package:orko_hubco/features/charging/data/models/charger_compatibility_model.dart';
import 'package:orko_hubco/features/charging/data/models/charging_station_detail_model.dart';
import 'package:orko_hubco/features/charging/data/models/favourite_station_model.dart';
import 'package:orko_hubco/features/charging/data/models/station_reviews_model.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

abstract class ChargingRemoteDataSource {
  /// Fetches the full detail for [stationId] using the QA base URL and the
  /// `charging_station_detail` endpoint resolved from Remote Config.
  Future<ChargingStationDetailModel> getStationDetail({
    required String stationId,
    required double latitude,
    required double longitude,
  });

  /// Fetches the user's favourite charging stations
  /// (`GET api/v1/charging-station/favourites/`).
  Future<List<FavouriteStationModel>> getFavourites();

  /// Adds [locationId] to the user's favourites
  /// (`POST api/v1/charging-station/favourites/`).
  Future<void> addFavourite(int locationId);

  /// Removes [locationId] from the user's favourites
  /// (`DELETE api/v1/charging-station/favourites/?location_id=...`).
  Future<void> removeFavourite(int locationId);

  /// Checks whether the vehicle [csmsVehicleId] is compatible with the charger
  /// identified by [chargePointId]
  /// (`POST api/v1/charging-station/charger-compatibility/`).
  Future<ChargerCompatibilityModel> checkChargerCompatibility({
    required int csmsVehicleId,
    required String chargePointId,
  });

  /// Fetches reviews + summary for [locationId]
  /// (`GET api/v1/charging-station/reviews/?location_id=...`).
  Future<StationReviewsModel> getReviews(int locationId);

  /// Adds a review (`POST api/v1/charging-station/reviews/`).
  Future<void> addReview({
    required int locationId,
    required int rating,
    required String description,
  });

  /// Updates the current user's review (`POST` with `review_id`).
  Future<void> updateReview({
    required int reviewId,
    required int rating,
    required String description,
  });

  /// Deletes the current user's review
  /// (`DELETE api/v1/charging-station/reviews/?review_id=...`).
  Future<void> deleteReview(int reviewId);
}

class ChargingRemoteDataSourceImpl implements ChargingRemoteDataSource {
  final ApiClient apiClient;

  const ChargingRemoteDataSourceImpl({required this.apiClient});

  /// Default favourites path, used when Remote Config doesn't provide the
  /// `charging_station_favourites` key (e.g. the Firebase parameter hasn't been
  /// updated yet). Keeps the feature working off the bundled contract.
  static const String _defaultFavouritesPath =
      'api/v1/charging-station/favourites/';

  /// Default reviews path, used when Remote Config omits the
  /// `charging_station_reviews` key.
  static const String _defaultReviewsPath =
      'api/v1/charging-station/reviews/';

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
        ApiClient.baseUrl,
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

  @override
  Future<List<FavouriteStationModel>> getFavourites() async {
    try {
      final url = _favouritesUrl();
      log('[Charging] Favourites URL (GET): $url');

      final response = await apiClient.get(url);

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is List) {
          return body
              .whereType<Map>()
              .map((e) => FavouriteStationModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList(growable: false);
        }
        // A successful response with no favourites is a valid empty list.
        return const [];
      }

      throw ServerException(
        message: _messageOf(data, 'Failed to load favourites'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> addFavourite(int locationId) async {
    try {
      final url = _favouritesUrl();
      log('[Charging] Favourites URL (POST): $url (location_id: $locationId)');

      final response = await apiClient.post(
        url,
        data: {'location_id': locationId},
      );

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return;

      throw ServerException(
        message: _messageOf(response.data, 'Failed to add favourite'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> removeFavourite(int locationId) async {
    try {
      final url = _favouritesUrl();
      log('[Charging] Favourites URL (DELETE): $url (location_id: $locationId)');

      final response = await apiClient.delete(
        url,
        queryParameters: {'location_id': locationId},
      );

      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) return;

      throw ServerException(
        message: _messageOf(response.data, 'Failed to remove favourite'),
        statusCode: response.statusCode,
      );
    } catch (e) {
      if (e is ServerException) rethrow;
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<ChargerCompatibilityModel> checkChargerCompatibility({
    required int csmsVehicleId,
    required String chargePointId,
  }) async {
    try {
      final url = _compatibilityUrl();
      log('[Charging] Compatibility URL (POST): $url '
          '(vehicle: $csmsVehicleId, charge_point_id: $chargePointId)');

      final response = await apiClient.post(
        url,
        data: {
          'csms_vehicle_id': csmsVehicleId,
          // Sent verbatim — charge_point_id can be up to 50 chars; never truncate.
          'charge_point_id': chargePointId,
        },
      );

      final data = response.data;
      if (response.statusCode == 200 && data is Map<String, dynamic>) {
        final body = data['body'];
        if (body is Map) {
          return ChargerCompatibilityModel.fromJson(
            Map<String, dynamic>.from(body),
          );
        }
      }

      throw ServerException(
        message: _messageOf(data, 'Could not check charger compatibility'),
        statusCode: response.statusCode,
      );
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      // 422 → "Vehicle not found." / "Charge station not found.";
      // 400 → validation errors. Surface the backend message verbatim.
      final data = e.response?.data;
      final message = (data is Map && data['message'] != null)
          ? data['message'].toString()
          : (e.message ?? 'Could not check charger compatibility');
      log('[Charging] Compatibility failed (${e.response?.statusCode}): $message');
      throw ServerException(
        message: message,
        statusCode: e.response?.statusCode,
        originalError: e,
      );
    } catch (e) {
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<StationReviewsModel> getReviews(int locationId) async {
    try {
      final url = _reviewsUrl();
      log('[Charging] Reviews URL (GET): $url (location_id: $locationId)');

      final response = await apiClient.get(
        url,
        queryParameters: {'location_id': locationId},
      );

      final data = response.data;
      _throwIfError(response.statusCode, data, 'Failed to load reviews');

      if (data is Map<String, dynamic> && data['body'] is Map) {
        return StationReviewsModel.fromJson(
          Map<String, dynamic>.from(data['body'] as Map),
        );
      }
      // A well-formed success with no body → treat as no reviews yet.
      return const StationReviewsModel();
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw _dioToServerException(e, 'Failed to load reviews');
    } catch (e) {
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> addReview({
    required int locationId,
    required int rating,
    required String description,
  }) async {
    try {
      final url = _reviewsUrl();
      log('[Charging] Reviews URL (POST add): $url '
          '(location_id: $locationId, rating: $rating)');

      final response = await apiClient.post(
        url,
        data: {
          'location_id': locationId,
          'rating': rating,
          'description': description,
        },
      );

      _throwIfError(response.statusCode, response.data, 'Failed to add review');
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw _dioToServerException(e, 'Failed to add review');
    } catch (e) {
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> updateReview({
    required int reviewId,
    required int rating,
    required String description,
  }) async {
    try {
      final url = _reviewsUrl();
      log('[Charging] Reviews URL (POST update): $url '
          '(review_id: $reviewId, rating: $rating)');

      final response = await apiClient.post(
        url,
        data: {
          'review_id': reviewId,
          'rating': rating,
          'description': description,
        },
      );

      _throwIfError(
        response.statusCode,
        response.data,
        'Failed to update review',
      );
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw _dioToServerException(e, 'Failed to update review');
    } catch (e) {
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  @override
  Future<void> deleteReview(int reviewId) async {
    try {
      final url = _reviewsUrl();
      log('[Charging] Reviews URL (DELETE): $url (review_id: $reviewId)');

      final response = await apiClient.delete(
        url,
        queryParameters: {'review_id': reviewId},
      );

      _throwIfError(
        response.statusCode,
        response.data,
        'Failed to delete review',
      );
    } on ServerException {
      rethrow;
    } on DioException catch (e) {
      throw _dioToServerException(e, 'Failed to delete review');
    } catch (e) {
      throw ServerException(message: e.toString(), originalError: e);
    }
  }

  /// Resolves the reviews endpoint against the QA base URL.
  String _reviewsUrl() {
    final config = RemoteConfigService.config;
    if (config == null) {
      throw const ServerException(message: 'Remote config not initialized');
    }
    final base = ApiClient.baseUrl.endsWith('/')
        ? ApiClient.baseUrl.substring(0, ApiClient.baseUrl.length - 1)
        : ApiClient.baseUrl;
    var path = config.apiConstants.apiEndpoints.chargingStationReviews.trim();
    if (path.isEmpty) path = _defaultReviewsPath;
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
  }

  /// Throws a [ServerException] when the request failed. Handles both real HTTP
  /// error codes and the API's convention of returning `200 OK` with an error
  /// `status` inside the body (e.g. `{ "status": 422, "message": "..." }`).
  void _throwIfError(int? httpStatus, dynamic data, String fallback) {
    final code = httpStatus ?? 0;
    if (code < 200 || code >= 300) {
      throw ServerException(
        message: _messageOf(data, fallback),
        statusCode: httpStatus,
      );
    }
    if (data is Map<String, dynamic>) {
      final bodyStatus = data['status'];
      if (bodyStatus is int && (bodyStatus < 200 || bodyStatus >= 300)) {
        throw ServerException(
          message: _messageOf(data, fallback),
          statusCode: bodyStatus,
        );
      }
    }
  }

  /// Maps a [DioException] to a [ServerException], surfacing the backend
  /// message verbatim when present.
  ServerException _dioToServerException(DioException e, String fallback) {
    final data = e.response?.data;
    final message = (data is Map && data['message'] != null)
        ? data['message'].toString()
        : (e.message ?? fallback);
    log('[Charging] Reviews failed (${e.response?.statusCode}): $message');
    return ServerException(
      message: message,
      statusCode: e.response?.statusCode,
      originalError: e,
    );
  }

  /// Resolves the charger-compatibility endpoint against the QA base URL.
  String _compatibilityUrl() {
    final config = RemoteConfigService.config;
    if (config == null) {
      throw const ServerException(message: 'Remote config not initialized');
    }
    final base = ApiClient.baseUrl.endsWith('/')
        ? ApiClient.baseUrl
            .substring(0, ApiClient.baseUrl.length - 1)
        : ApiClient.baseUrl;
    var path = config.apiConstants.apiEndpoints.chargerCompatibility.trim();
    // Fall back to the bundled contract path when Remote Config omits the key.
    if (path.isEmpty) path = 'api/v1/charging-station/charger-compatibility/';
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
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

  /// Resolves the favourites endpoint against the QA base URL.
  String _favouritesUrl() {
    final config = RemoteConfigService.config;
    if (config == null) {
      throw const ServerException(message: 'Remote config not initialized');
    }
    final base = ApiClient.baseUrl.endsWith('/')
        ? ApiClient.baseUrl
            .substring(0, ApiClient.baseUrl.length - 1)
        : ApiClient.baseUrl;
    var path = config.apiConstants.apiEndpoints.chargingStationFavourites.trim();
    if (path.isEmpty) path = _defaultFavouritesPath;
    if (path.startsWith('/')) path = path.substring(1);
    return '$base/$path';
  }

  /// Extracts a human-readable message from an error response body.
  String _messageOf(dynamic data, String fallback) {
    if (data is Map<String, dynamic> && data['message'] != null) {
      return data['message'].toString();
    }
    return fallback;
  }
}

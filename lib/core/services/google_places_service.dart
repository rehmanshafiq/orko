import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:orko_hubco/core/constants/api_constants.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

/// A single autocomplete suggestion returned by the Places API.
@immutable
class PlaceSuggestion {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  final String placeId;

  /// Main name of the place (e.g. "Lahore").
  final String primaryText;

  /// Supporting context (e.g. "Punjab, Pakistan"). May be empty.
  final String secondaryText;

  String get description =>
      secondaryText.isEmpty ? primaryText : '$primaryText, $secondaryText';
}

/// A resolved place with coordinates, returned after fetching place details.
@immutable
class PlaceLocation {
  const PlaceLocation({
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final String address;
  final double latitude;
  final double longitude;
}

/// Thin wrapper over the Google Places Web Service (Autocomplete + Details).
///
/// Uses its own [Dio] instance so the app's auth/domain interceptors and the
/// postman-echo base URL never leak into Google requests.
class GooglePlacesService {
  GooglePlacesService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 15),
                receiveTimeout: const Duration(seconds: 15),
              ),
            );

  final Dio _dio;

  /// Remote-config values take precedence; fall back to the bundled constants
  /// when the config hasn't resolved or omits a value.
  String get _apiKey {
    final fromConfig =
        RemoteConfigService.config?.apiConstants.googlePlacesApiKey;
    return (fromConfig == null || fromConfig.trim().isEmpty)
        ? ApiConstants.googlePlacesApiKey
        : fromConfig;
  }

  String get _autocompleteUrl {
    final fromConfig =
        RemoteConfigService.config?.apiConstants.autocompleteUrl;
    return (fromConfig == null || fromConfig.trim().isEmpty)
        ? 'https://maps.googleapis.com/maps/api/place/autocomplete/json'
        : fromConfig;
  }

  String get _detailsUrl {
    final fromConfig = RemoteConfigService.config?.apiConstants.detailsUrl;
    return (fromConfig == null || fromConfig.trim().isEmpty)
        ? 'https://maps.googleapis.com/maps/api/place/details/json'
        : fromConfig;
  }

  /// Returns autocomplete predictions for [input], biased to Pakistan.
  ///
  /// [sessionToken] groups autocomplete calls with the follow-up details call
  /// for billing; pass the same token for one search session.
  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    String? sessionToken,
  }) async {
    final query = input.trim();
    if (query.isEmpty) return const [];

    try {
      final response = await _dio.get(
        _autocompleteUrl,
        queryParameters: {
          'input': query,
          'key': _apiKey,
          'components': 'country:pk',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      final status = data['status'] as String?;
      if (status != 'OK' && status != 'ZERO_RESULTS') {
        debugPrint('[Places] autocomplete status=$status ${data['error_message']}');
        return const [];
      }

      final predictions = (data['predictions'] as List?) ?? const [];
      return predictions.map((p) {
        final map = p as Map<String, dynamic>;
        final structured =
            (map['structured_formatting'] as Map<String, dynamic>?) ?? const {};
        return PlaceSuggestion(
          placeId: map['place_id'] as String? ?? '',
          primaryText: structured['main_text'] as String? ??
              map['description'] as String? ??
              '',
          secondaryText: structured['secondary_text'] as String? ?? '',
        );
      }).where((s) => s.placeId.isNotEmpty).toList();
    } catch (e) {
      debugPrint('[Places] autocomplete failed: $e');
      return const [];
    }
  }

  /// Resolves a [placeId] into a [PlaceLocation] with coordinates.
  Future<PlaceLocation?> details(
    String placeId, {
    String? sessionToken,
  }) async {
    if (placeId.isEmpty) return null;

    try {
      final response = await _dio.get(
        _detailsUrl,
        queryParameters: {
          'place_id': placeId,
          'key': _apiKey,
          'fields': 'name,formatted_address,geometry/location',
          if (sessionToken != null) 'sessiontoken': sessionToken,
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (data['status'] != 'OK') {
        debugPrint('[Places] details status=${data['status']} '
            '${data['error_message']}');
        return null;
      }

      final result = data['result'] as Map<String, dynamic>;
      final location = (result['geometry']
          as Map<String, dynamic>)['location'] as Map<String, dynamic>;

      return PlaceLocation(
        name: result['name'] as String? ?? '',
        address: result['formatted_address'] as String? ?? '',
        latitude: (location['lat'] as num).toDouble(),
        longitude: (location['lng'] as num).toDouble(),
      );
    } catch (e) {
      debugPrint('[Places] details failed: $e');
      return null;
    }
  }
}

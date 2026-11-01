/// Query for `GET /cvp/places/autocomplete/`.
class PlaceAutocompleteParams {
  const PlaceAutocompleteParams({
    required this.input,
    this.sessionToken,
    this.latitude,
    this.longitude,
    this.radius,
    this.components,
    this.language,
  });

  /// Backend-accepted bounds for [radius], in metres.
  static const int minRadius = 1;
  static const int maxRadius = 50000;

  final String input;

  /// Groups every autocomplete call of one search with its details call.
  final String? sessionToken;

  /// Optional location bias. Sent only when both are present.
  final double? latitude;
  final double? longitude;

  /// Bias radius in metres; clamped to [minRadius]–[maxRadius] and sent only
  /// alongside a location.
  final int? radius;

  /// e.g. `country:pk`.
  final String? components;
  final String? language;

  Map<String, dynamic> toQuery() {
    final hasLocation = latitude != null && longitude != null;
    return {
      'input': input.trim(),
      if (_present(sessionToken)) 'session_token': sessionToken,
      if (hasLocation) ...{
        'latitude': latitude,
        'longitude': longitude,
        if (radius != null) 'radius': radius!.clamp(minRadius, maxRadius),
      },
      if (_present(components)) 'components': components,
      if (_present(language)) 'language': language,
    };
  }
}

/// Query for `GET /cvp/places/details/`.
class PlaceDetailsParams {
  const PlaceDetailsParams({
    required this.placeId,
    this.sessionToken,
    this.language,
  });

  final String placeId;

  /// The same token used for the preceding autocomplete calls.
  final String? sessionToken;
  final String? language;

  Map<String, dynamic> toQuery() => {
        'place_id': placeId,
        if (_present(sessionToken)) 'session_token': sessionToken,
        if (_present(language)) 'language': language,
      };
}

bool _present(String? value) => value != null && value.trim().isNotEmpty;

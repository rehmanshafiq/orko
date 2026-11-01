import 'package:equatable/equatable.dart';

/// A single prediction from `GET /cvp/places/autocomplete/`.
class PlaceSuggestion extends Equatable {
  const PlaceSuggestion({
    required this.placeId,
    required this.primaryText,
    required this.secondaryText,
  });

  final String placeId;

  /// Main name of the place (e.g. "Lahore") — the backend's `main_text`.
  final String primaryText;

  /// Supporting context (e.g. "Punjab, Pakistan") — the backend's
  /// `secondary_text`. May be empty.
  final String secondaryText;

  @override
  List<Object?> get props => [placeId, primaryText, secondaryText];
}

/// A resolved place with coordinates, from `GET /cvp/places/details/` (or the
/// device GPS for "Use my current location").
class PlaceLocation extends Equatable {
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

  @override
  List<Object?> get props => [name, address, latitude, longitude];
}

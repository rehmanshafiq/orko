import 'package:orko_hubco/features/trip/data/models/trip_json.dart';
import 'package:orko_hubco/features/trip/domain/entities/place_entity.dart';

/// Maps one entry of `body.predictions` from `GET /cvp/places/autocomplete/`.
class PlaceSuggestionModel extends PlaceSuggestion {
  const PlaceSuggestionModel({
    required super.placeId,
    required super.primaryText,
    required super.secondaryText,
  });

  factory PlaceSuggestionModel.fromJson(Map<String, dynamic> json) {
    final mainText = TripJson.asString(json['main_text']).trim();
    return PlaceSuggestionModel(
      placeId: TripJson.asString(json['place_id']).trim(),
      primaryText: mainText.isNotEmpty
          ? mainText
          : TripJson.asString(json['description']).trim(),
      secondaryText: TripJson.asString(json['secondary_text']).trim(),
    );
  }
}

/// Maps `body` from `GET /cvp/places/details/`.
class PlaceLocationModel extends PlaceLocation {
  const PlaceLocationModel({
    required super.name,
    required super.address,
    required super.latitude,
    required super.longitude,
  });

  /// Returns `null` when the payload has no usable coordinates.
  static PlaceLocationModel? tryFromJson(Map<String, dynamic> json) {
    final lat = TripJson.asDoubleOrNull(json['latitude']);
    final lng = TripJson.asDoubleOrNull(json['longitude']);
    if (lat == null || lng == null) return null;
    final name = TripJson.asString(json['name']).trim();
    final address = TripJson.asString(json['formatted_address']).trim();
    return PlaceLocationModel(
      name: name.isNotEmpty ? name : address,
      address: address,
      latitude: lat,
      longitude: lng,
    );
  }
}

import 'package:orko_hubco/features/charging/domain/entities/favourite_station_entity.dart';

/// Maps an item of the `body` array from
/// `GET api/v1/charging-station/favourites/` into a [FavouriteStationEntity].
/// Parsed defensively so a missing or malformed key can never throw.
class FavouriteStationModel extends FavouriteStationEntity {
  const FavouriteStationModel({
    required super.id,
    required super.locationId,
  });

  factory FavouriteStationModel.fromJson(Map<String, dynamic> json) {
    return FavouriteStationModel(
      id: _asInt(json['id']),
      locationId: _asInt(json['location_id']),
    );
  }

  static int _asInt(dynamic value) {
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
}

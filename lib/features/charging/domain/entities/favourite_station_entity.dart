import 'package:equatable/equatable.dart';

/// A single favourited charging station, as returned by
/// `GET api/v1/charging-station/favourites/`.
class FavouriteStationEntity extends Equatable {
  const FavouriteStationEntity({
    required this.id,
    required this.locationId,
  });

  /// The favourite record id.
  final int id;

  /// The charging-station location id this favourite points to.
  final int locationId;

  @override
  List<Object?> get props => [id, locationId];
}

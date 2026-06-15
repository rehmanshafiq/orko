import 'package:equatable/equatable.dart';

class HubcoLocationEntity extends Equatable {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool status;

  /// Distance from the requesting device, in kilometers (0 when unknown).
  final double distance;

  /// Remote station icon URL (with background) when provided by the API.
  final String iconUrl;

  const HubcoLocationEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
    this.distance = 0,
    this.iconUrl = '',
  });

  @override
  List<Object?> get props => [
        id,
        name,
        address,
        latitude,
        longitude,
        status,
        distance,
        iconUrl,
      ];
}

import 'package:equatable/equatable.dart';

class HubcoLocationEntity extends Equatable {
  final int id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final bool status;

  const HubcoLocationEntity({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.status,
  });

  @override
  List<Object?> get props => [id, name, address, latitude, longitude, status];
}

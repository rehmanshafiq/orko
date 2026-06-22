import 'package:equatable/equatable.dart';

/// A car make/brand from `GET api/v1/vehicle/makes/` (the `body.results` items).
class VehicleMakeEntity extends Equatable {
  const VehicleMakeEntity({
    required this.id,
    required this.name,
  });

  final int id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

import 'package:equatable/equatable.dart';

/// A car make/brand from `GET api/v1/vehicle/makes/` (the `body.results` items).
class VehicleMakeEntity extends Equatable {
  const VehicleMakeEntity({
    required this.id,
    required this.name,
    this.logo = '',
  });

  final int id;
  final String name;

  /// Brand logo URL from the `logo` field (empty when not provided).
  final String logo;

  @override
  List<Object?> get props => [id, name, logo];
}

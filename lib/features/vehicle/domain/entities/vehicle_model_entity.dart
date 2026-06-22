import 'package:equatable/equatable.dart';

/// A car model from `GET api/v1/vehicle/models/?md_make__id=<id>`
/// (the `body.results` items). [connectorType] drives charger compatibility.
class VehicleModelEntity extends Equatable {
  const VehicleModelEntity({
    required this.id,
    required this.name,
    this.connectorType,
  });

  final int id;
  final String name;

  /// e.g. `CCS2`, `Type 2`. May be null/empty when the backend has no value.
  final String? connectorType;

  @override
  List<Object?> get props => [id, name, connectorType];
}

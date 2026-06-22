import 'package:equatable/equatable.dart';

/// Result of `POST api/v1/vehicle/add-vehicle/` (the `body` object). The [id]
/// is the new `csms_vehicle_id`.
class CreatedVehicleEntity extends Equatable {
  const CreatedVehicleEntity({
    required this.id,
    required this.mdMake,
    required this.mdModel,
  });

  final int id;
  final int mdMake;
  final int mdModel;

  @override
  List<Object?> get props => [id, mdMake, mdModel];
}

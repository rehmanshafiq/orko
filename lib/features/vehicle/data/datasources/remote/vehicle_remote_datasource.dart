import 'package:orko_hubco/features/vehicle/data/models/created_vehicle_model.dart';
import 'package:orko_hubco/features/vehicle/data/models/user_vehicle_model.dart';
import 'package:orko_hubco/features/vehicle/data/models/vehicle_make_model.dart';
import 'package:orko_hubco/features/vehicle/data/models/vehicle_model_model.dart';

abstract class VehicleRemoteDataSource {
  /// `GET api/v1/vehicle/makes/` — brands for the "Select Make" dropdown.
  Future<List<VehicleMakeModel>> getMakes();

  /// `GET api/v1/vehicle/models/?md_make__id=<makeId>` — models for a make.
  Future<List<VehicleModelModel>> getModels({required int makeId});

  /// `POST api/v1/vehicle/add-vehicle/` — creates a vehicle for the user.
  Future<CreatedVehicleModel> addVehicle({
    required int mdMake,
    required int mdModel,
    required String year,
    String? vehicleRfid,
  });

  /// `GET api/v1/vehicle/user-vehicle/` — the logged-in user's vehicles.
  Future<List<UserVehicleModel>> getUserVehicles();

  /// `DELETE api/v1/vehicle/add-vehicle/` — soft-deletes the vehicle [id].
  Future<void> deleteVehicle({required int id});

  /// `POST api/v1/vehicle/custom-make/` — creates a tenant custom make and
  /// returns it (so it can be selected in the make dropdown).
  Future<VehicleMakeModel> createCustomMake({required String name});

  /// `POST api/v1/vehicle/custom-model/` — creates a custom model under
  /// [mdMake] and returns it.
  Future<VehicleModelModel> createCustomModel({
    required int mdMake,
    required String name,
    required String connectorType,
    required double batteryCapacity,
    required int mileage,
  });
}

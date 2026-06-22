import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/entities/charger_compatibility_entity.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

class CheckChargerCompatibilityUseCase
    implements
        UseCase<ChargerCompatibilityEntity, CheckChargerCompatibilityParams> {
  final ChargingRepository repository;

  const CheckChargerCompatibilityUseCase(this.repository);

  @override
  Future<Either<Failure, ChargerCompatibilityEntity>> call(
    CheckChargerCompatibilityParams params,
  ) {
    return repository.checkChargerCompatibility(
      csmsVehicleId: params.csmsVehicleId,
      chargePointId: params.chargePointId,
    );
  }
}

class CheckChargerCompatibilityParams {
  final int csmsVehicleId;
  final String chargePointId;

  const CheckChargerCompatibilityParams({
    required this.csmsVehicleId,
    required this.chargePointId,
  });
}

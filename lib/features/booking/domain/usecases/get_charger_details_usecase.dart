import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/booking/domain/entities/charger_details_entity.dart';
import 'package:orko_hubco/features/booking/domain/repositories/booking_repository.dart';

class GetChargerDetailsUseCase
    implements UseCase<ChargerDetailsEntity, GetChargerDetailsParams> {
  final BookingRepository repository;

  const GetChargerDetailsUseCase(this.repository);

  @override
  Future<Either<Failure, ChargerDetailsEntity>> call(
    GetChargerDetailsParams params,
  ) {
    return repository.getChargerDetails(locationId: params.locationId);
  }
}

class GetChargerDetailsParams {
  const GetChargerDetailsParams({required this.locationId});

  final int locationId;
}

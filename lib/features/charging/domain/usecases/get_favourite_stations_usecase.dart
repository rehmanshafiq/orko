import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/charging/domain/entities/favourite_station_entity.dart';
import 'package:orko_hubco/features/charging/domain/repositories/charging_repository.dart';

class GetFavouriteStationsUseCase
    implements UseCase<List<FavouriteStationEntity>, NoParams> {
  final ChargingRepository repository;

  const GetFavouriteStationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<FavouriteStationEntity>>> call(NoParams params) {
    return repository.getFavourites();
  }
}

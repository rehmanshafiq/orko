import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/domain/entities/station_result_entity.dart';
import 'package:orko_hubco/features/search/domain/repositories/search_repository.dart';

class GetPopularStationsUseCase
    implements UseCase<List<StationResultEntity>, PopularStationsParams> {
  final SearchRepository repository;

  const GetPopularStationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<StationResultEntity>>> call(
    PopularStationsParams params,
  ) {
    return repository.getPopularStations(
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class PopularStationsParams extends Equatable {
  const PopularStationsParams({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [latitude, longitude];
}

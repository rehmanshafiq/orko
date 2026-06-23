import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/search/domain/entities/station_result_entity.dart';
import 'package:orko_hubco/features/search/domain/repositories/search_repository.dart';

class SearchStationsUseCase
    implements UseCase<List<StationResultEntity>, SearchStationsParams> {
  final SearchRepository repository;

  const SearchStationsUseCase(this.repository);

  @override
  Future<Either<Failure, List<StationResultEntity>>> call(
    SearchStationsParams params,
  ) {
    return repository.searchStations(
      query: params.query,
      latitude: params.latitude,
      longitude: params.longitude,
    );
  }
}

class SearchStationsParams extends Equatable {
  const SearchStationsParams({
    required this.query,
    required this.latitude,
    required this.longitude,
  });

  final String query;
  final double latitude;
  final double longitude;

  @override
  List<Object?> get props => [query, latitude, longitude];
}

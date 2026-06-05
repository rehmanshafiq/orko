import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/map/data/datasources/local/map_local_datasource.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/domain/repositories/map_repository.dart';

class MapRepositoryImpl implements MapRepository {
  final MapLocalDataSource localDataSource;

  const MapRepositoryImpl({
    required this.localDataSource,
  });

  @override
  Future<Either<Failure, List<HubcoLocationEntity>>> getHubcoLocations() async {
    try {
      final stations = await localDataSource.getHubcoLocations();
      return Right(stations);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

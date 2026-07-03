import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/trip/data/datasources/remote/trip_remote_datasource.dart';
import 'package:orko_hubco/features/trip/domain/entities/saved_trip_entity.dart';
import 'package:orko_hubco/features/trip/domain/entities/trip_plan_entity.dart';
import 'package:orko_hubco/features/trip/domain/repositories/trip_repository.dart';
import 'package:orko_hubco/features/trip/domain/usecases/trip_plan_params.dart';

class TripRepositoryImpl implements TripRepository {
  final TripRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const TripRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, TripPlanEntity>> planTrip(TripPlanParams params) {
    return _run(() => remoteDataSource.planTrip(params));
  }

  @override
  Future<Either<Failure, SavedTripEntity>> saveTrip(TripPlanParams params) {
    return _run(() => remoteDataSource.saveTrip(params));
  }

  @override
  Future<Either<Failure, List<SavedTripEntity>>> getSavedTrips() {
    return _run(() => remoteDataSource.getSavedTrips());
  }

  @override
  Future<Either<Failure, SavedTripEntity>> getSavedTripDetail(int id) {
    return _run(() => remoteDataSource.getSavedTripDetail(id));
  }

  @override
  Future<Either<Failure, String>> deleteSavedTrip(int id) {
    return _run(() => remoteDataSource.deleteSavedTrip(id));
  }

  @override
  Future<Either<Failure, SavedTripEntity>> editTrip({
    required int tripId,
    required TripPlanParams params,
  }) {
    return _run(() => remoteDataSource.editTrip(tripId: tripId, params: params));
  }

  /// Shared connectivity guard + exception→failure mapping for every call.
  Future<Either<Failure, T>> _run<T>(Future<T> Function() action) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      return Right(await action());
    } on ServerException catch (e) {
      if (e.statusCode == 401) {
        return const Left(UnauthorizedFailure());
      }
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

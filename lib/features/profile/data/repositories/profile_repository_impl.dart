import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/network/network_info.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/profile/data/datasources/remote/profile_remote_datasource.dart';
import 'package:orko_hubco/features/profile/domain/entities/charging_stats_entity.dart';
import 'package:orko_hubco/features/profile/domain/repositories/profile_repository.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  const ProfileRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, ChargingStatsEntity>> getChargingStats() async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure());
    }
    try {
      final stats = await remoteDataSource.getChargingStats();
      return Right(stats);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message, statusCode: e.statusCode));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}

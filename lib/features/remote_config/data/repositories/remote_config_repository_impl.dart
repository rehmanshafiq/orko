import 'package:orko_hubco/core/error/exceptions.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/remote_config/data/datasources/remote/remote_config_datasource.dart';
import 'package:orko_hubco/features/remote_config/domain/entities/remote_config_entity.dart';
import 'package:orko_hubco/features/remote_config/domain/repositories/remote_config_repository.dart';

class RemoteConfigRepositoryImpl implements RemoteConfigRepository {
  final RemoteConfigDataSource dataSource;

  const RemoteConfigRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, RemoteConfigEntity>> fetchConfig() async {
    try {
      final config = await dataSource.fetchConfig();
      return Right(config);
    } on ServerException catch (e) {
      return Left(ServerFailure(message: e.message));
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  String getString(String key, {String defaultValue = ''}) {
    return dataSource.getString(key, defaultValue: defaultValue);
  }

  @override
  bool getBool(String key, {bool defaultValue = false}) {
    return dataSource.getBool(key, defaultValue: defaultValue);
  }

  @override
  int getInt(String key, {int defaultValue = 0}) {
    return dataSource.getInt(key, defaultValue: defaultValue);
  }
}

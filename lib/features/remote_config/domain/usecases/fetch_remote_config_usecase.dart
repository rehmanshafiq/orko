import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/remote_config/domain/entities/remote_config_entity.dart';
import 'package:orko_hubco/features/remote_config/domain/repositories/remote_config_repository.dart';

/// Fetches remote config values.
class FetchRemoteConfigUseCase implements UseCase<RemoteConfigEntity, NoParams> {
  final RemoteConfigRepository repository;

  const FetchRemoteConfigUseCase(this.repository);

  @override
  Future<Either<Failure, RemoteConfigEntity>> call(NoParams params) {
    return repository.fetchConfig();
  }
}

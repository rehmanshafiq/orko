import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Fetches the current user (`get_user`) and refreshes the cached user.
class GetUserUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  const GetUserUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.getUser();
  }
}

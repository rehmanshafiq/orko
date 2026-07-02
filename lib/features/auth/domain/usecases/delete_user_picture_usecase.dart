import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Removes the current profile picture (`delete_user_picture`), then refreshes
/// the cached user via `get_user`. Returns the up-to-date [UserEntity].
class DeleteUserPictureUseCase implements UseCase<UserEntity, NoParams> {
  final AuthRepository repository;

  const DeleteUserPictureUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) {
    return repository.deleteUserPicture();
  }
}

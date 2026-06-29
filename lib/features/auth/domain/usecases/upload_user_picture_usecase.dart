import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Uploads a new profile picture (`upload_user_picture`), then refreshes the
/// cached user via `get_user`. Returns the up-to-date [UserEntity].
class UploadUserPictureUseCase implements UseCase<UserEntity, String> {
  final AuthRepository repository;

  const UploadUserPictureUseCase(this.repository);

  /// [params] is the absolute path of the picked image file.
  @override
  Future<Either<Failure, UserEntity>> call(String params) {
    return repository.uploadUserPicture(params);
  }
}

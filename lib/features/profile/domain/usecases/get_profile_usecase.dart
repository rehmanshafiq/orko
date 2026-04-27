import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';
import 'package:orko_hubco/features/profile/domain/repositories/profile_repository.dart';

/// Fetches the current user profile.
class GetProfileUseCase implements UseCase<ProfileEntity, NoParams> {
  final ProfileRepository repository;

  const GetProfileUseCase(this.repository);

  @override
  Future<Either<Failure, ProfileEntity>> call(NoParams params) {
    return repository.getProfile();
  }
}

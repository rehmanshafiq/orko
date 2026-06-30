import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Permanently deletes the signed-in user's account and clears local session
/// data. Returns the server's confirmation message on success.
class DeleteAccountUseCase implements UseCase<String, NoParams> {
  final AuthRepository repository;

  const DeleteAccountUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(NoParams params) {
    return repository.deleteAccount();
  }
}

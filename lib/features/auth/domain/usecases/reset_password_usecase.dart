import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Forgot-password step 3: sets a new password, authorized with the token
/// returned by verify-otp. Returns the server's confirmation message.
class ResetPasswordUseCase implements UseCase<String, ResetPasswordParams> {
  final AuthRepository repository;

  const ResetPasswordUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ResetPasswordParams params) {
    return repository.resetPassword(
      accessToken: params.accessToken,
      newPassword: params.newPassword,
      confirmPassword: params.confirmPassword,
    );
  }
}

class ResetPasswordParams {
  const ResetPasswordParams({
    required this.accessToken,
    required this.newPassword,
    required this.confirmPassword,
  });

  final String accessToken;
  final String newPassword;
  final String confirmPassword;
}

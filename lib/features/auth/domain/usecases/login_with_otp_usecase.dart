import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Starts the forgot-password flow: requests an OTP for [email] and returns the
/// issued `otp_id`.
class LoginWithOtpUseCase implements UseCase<int, LoginWithOtpParams> {
  final AuthRepository repository;

  const LoginWithOtpUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(LoginWithOtpParams params) {
    return repository.loginWithOtp(email: params.email);
  }
}

class LoginWithOtpParams {
  const LoginWithOtpParams({required this.email});

  final String email;
}

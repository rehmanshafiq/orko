import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Starts the forgot-password flow: requests an OTP for the given phone number
/// or email and returns the issued `otp_id`.
class LoginWithOtpUseCase implements UseCase<int, LoginWithOtpParams> {
  final AuthRepository repository;

  const LoginWithOtpUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(LoginWithOtpParams params) {
    return repository.loginWithOtp(
      phoneNumberEmail: params.phoneNumberEmail,
      countryCode: params.countryCode,
    );
  }
}

class LoginWithOtpParams {
  const LoginWithOtpParams({
    required this.phoneNumberEmail,
    required this.countryCode,
  });

  /// Phone number in local format (e.g. `03112208527`) or an email address.
  final String phoneNumberEmail;

  /// Dialing code, e.g. `+92`.
  final String countryCode;
}

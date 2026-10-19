import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Starts the forgot-password flow: requests an OTP for the given phone number
/// and returns the issued `otp_id`.
class LoginWithOtpUseCase implements UseCase<int, LoginWithOtpParams> {
  final AuthRepository repository;

  const LoginWithOtpUseCase(this.repository);

  @override
  Future<Either<Failure, int>> call(LoginWithOtpParams params) {
    return repository.loginWithOtp(
      phoneNumber: params.phoneNumber,
      countryCode: params.countryCode,
    );
  }
}

class LoginWithOtpParams {
  const LoginWithOtpParams({
    required this.phoneNumber,
    required this.countryCode,
  });

  /// National number without the dialing code, e.g. `3112208527`.
  final String phoneNumber;

  /// Dialing code, e.g. `+92`.
  final String countryCode;
}

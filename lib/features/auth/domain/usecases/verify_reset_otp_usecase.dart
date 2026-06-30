import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Forgot-password step 2: verifies the OTP and returns the short-lived access
/// token that authorizes the password reset.
class VerifyResetOtpUseCase implements UseCase<String, VerifyResetOtpParams> {
  final AuthRepository repository;

  const VerifyResetOtpUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(VerifyResetOtpParams params) {
    return repository.verifyResetOtp(otpId: params.otpId, otp: params.otp);
  }
}

class VerifyResetOtpParams {
  const VerifyResetOtpParams({required this.otpId, required this.otp});

  final int otpId;
  final String otp;
}

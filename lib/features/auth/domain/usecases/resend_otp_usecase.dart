import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Encapsulates the resend-OTP business logic.
///
/// Returns the confirmation message issued by the server on success.
class ResendOtpUseCase implements UseCase<String, ResendOtpParams> {
  final AuthRepository repository;

  const ResendOtpUseCase(this.repository);

  @override
  Future<Either<Failure, String>> call(ResendOtpParams params) {
    return repository.resendOtp(otpId: params.otpId);
  }
}

class ResendOtpParams {
  /// Pending OTP id for the sign-in flow. Omit for signup verification, which
  /// authorizes with the saved access token instead.
  final String? otpId;

  const ResendOtpParams({this.otpId});
}

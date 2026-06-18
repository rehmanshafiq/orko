import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Encapsulates the OTP verification business logic.
class VerifyOtpUseCase implements UseCase<void, VerifyOtpParams> {
  final AuthRepository repository;

  const VerifyOtpUseCase(this.repository);

  @override
  Future<Either<Failure, void>> call(VerifyOtpParams params) {
    return repository.verifyOtp(otp: params.otp);
  }
}

class VerifyOtpParams {
  final String otp;

  const VerifyOtpParams({required this.otp});
}

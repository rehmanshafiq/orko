import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Step 2 of the phone-change flow: verifies the OTP (`change_phone_verify`),
/// updating the number and returning the refreshed [UserEntity].
class VerifyPhoneChangeUseCase
    implements UseCase<UserEntity, VerifyPhoneChangeParams> {
  final AuthRepository repository;

  const VerifyPhoneChangeUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifyPhoneChangeParams params) {
    return repository.verifyPhoneChange(otpId: params.otpId, otp: params.otp);
  }
}

class VerifyPhoneChangeParams {
  const VerifyPhoneChangeParams({required this.otpId, required this.otp});

  final int otpId;
  final String otp;
}

import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Step 2 of the email-change flow: verifies the OTP (`change_email_verify`),
/// updating the email and returning the refreshed [UserEntity].
class VerifyEmailChangeUseCase
    implements UseCase<UserEntity, VerifyEmailChangeParams> {
  final AuthRepository repository;

  const VerifyEmailChangeUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(VerifyEmailChangeParams params) {
    return repository.verifyEmailChange(params.otp);
  }
}

class VerifyEmailChangeParams {
  const VerifyEmailChangeParams({required this.otp});

  final String otp;
}

import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Encapsulates the login business logic.
class LoginUseCase implements UseCase<SignUpResultEntity, LoginParams> {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  @override
  Future<Either<Failure, SignUpResultEntity>> call(LoginParams params) {
    return repository.login(
      phoneNumber: params.phoneNumber,
      countryCode: params.countryCode,
      password: params.password,
    );
  }
}

class LoginParams {
  final String phoneNumber;
  final String countryCode;
  final String password;

  const LoginParams({
    required this.phoneNumber,
    required this.countryCode,
    required this.password,
  });
}

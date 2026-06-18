import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Encapsulates the complete-signup business logic.
class SignUpUseCase implements UseCase<SignUpResultEntity, SignUpParams> {
  final AuthRepository repository;

  const SignUpUseCase(this.repository);

  @override
  Future<Either<Failure, SignUpResultEntity>> call(SignUpParams params) {
    return repository.signUp(
      name: params.name,
      phoneNumber: params.phoneNumber,
      countryCode: params.countryCode,
      email: params.email,
      password: params.password,
      confirmPassword: params.confirmPassword,
    );
  }
}

class SignUpParams {
  final String name;
  final String phoneNumber;
  final String countryCode;
  final String email;
  final String password;
  final String confirmPassword;

  const SignUpParams({
    required this.name,
    required this.phoneNumber,
    required this.countryCode,
    required this.email,
    required this.password,
    required this.confirmPassword,
  });
}

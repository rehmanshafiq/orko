import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/login_method.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Exchanges a Google account's name + email for an authenticated session via
/// the `login_with_google` endpoint.
class LoginWithGoogleUseCase
    implements UseCase<SignUpResultEntity, LoginWithGoogleParams> {
  final AuthRepository repository;

  const LoginWithGoogleUseCase(this.repository);

  @override
  Future<Either<Failure, SignUpResultEntity>> call(
    LoginWithGoogleParams params,
  ) {
    return repository.loginWithGoogle(
      name: params.name,
      email: params.email,
      token: params.token,
      loginMethod: params.loginMethod,
    );
  }
}

class LoginWithGoogleParams {
  final String name;
  final String email;

  /// Firebase ID token minted from the Google / Apple credential.
  final String token;

  /// Which provider produced [token] — Google and Apple share this endpoint.
  final LoginMethod loginMethod;

  const LoginWithGoogleParams({
    required this.name,
    required this.email,
    required this.token,
    this.loginMethod = LoginMethod.google,
  });
}

import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';

/// Result of a successful sign-up (complete-signup) call.
///
/// Carries the issued [accessToken] and the created [user]. The access token is
/// persisted to local storage by the repository.
class SignUpResultEntity extends Equatable {
  final String accessToken;
  final UserEntity user;
  final bool otpVerificationRequired;

  const SignUpResultEntity({
    required this.accessToken,
    required this.user,
    this.otpVerificationRequired = false,
  });

  @override
  List<Object?> get props => [accessToken, user, otpVerificationRequired];
}

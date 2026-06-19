import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';

/// All possible states for the Auth feature.
abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — nothing has happened yet.
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Loading state — waiting for an async operation.
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// Authenticated state — user is logged in.
class AuthAuthenticated extends AuthState {
  final UserEntity user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// Unauthenticated state — no valid session.
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// Sign-up completed — access token saved locally; proceed to OTP verification.
class SignUpSuccess extends AuthState {
  final SignUpResultEntity result;

  const SignUpSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

/// OTP verification in progress.
class OtpVerifying extends AuthState {
  const OtpVerifying();
}

/// OTP verified successfully — proceed to the home shell.
class OtpVerified extends AuthState {
  const OtpVerified();
}

/// A resend-OTP request is in flight.
class OtpResending extends AuthState {
  const OtpResending();
}

/// A fresh OTP was sent — carries the server's confirmation message.
class OtpResent extends AuthState {
  final String message;

  const OtpResent(this.message);

  @override
  List<Object?> get props => [message];
}

/// Resending the OTP failed. Kept distinct from [AuthError] so the entered
/// code is preserved (the previous OTP may still be valid).
class OtpResendFailure extends AuthState {
  final String message;

  const OtpResendFailure(this.message);

  @override
  List<Object?> get props => [message];
}

/// Error state — something went wrong.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

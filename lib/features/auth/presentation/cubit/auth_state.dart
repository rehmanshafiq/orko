import 'package:equatable/equatable.dart';
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

/// Error state — something went wrong.
class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

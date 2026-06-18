import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/services/google_auth_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/register_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/signup_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';

import '../../domain/usecases/logout_usecase.dart';

/// Auth Cubit — manages authentication state.
/// Depends only on use cases (domain layer), never on data layer directly.
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final RegisterUseCase _registerUseCase;
  final SignUpUseCase _signUpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final LogoutUseCase _logoutUseCase;
  final GoogleAuthService _googleAuthService;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required RegisterUseCase registerUseCase,
    required SignUpUseCase signUpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required LogoutUseCase logoutUseCase,
    required GoogleAuthService googleAuthService,
  })  : _loginUseCase = loginUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _registerUseCase = registerUseCase,
        _signUpUseCase = signUpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _logoutUseCase = logoutUseCase,
        _googleAuthService = googleAuthService,
        super(const AuthInitial());

  /// Performs login via the `login_api` endpoint. On success the access token +
  /// user are persisted and [AuthAuthenticated] is emitted.
  Future<void> login({
    required String phoneNumber,
    required String countryCode,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _loginUseCase(
      LoginParams(
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        password: password,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (loginResult) => emit(AuthAuthenticated(loginResult.user)),
    );
  }

  /// Signs in with Google: launches the native account picker, then exchanges
  /// the account's name + email for a session via `login_with_google`. On
  /// success the access token + user are persisted and [AuthAuthenticated] is
  /// emitted. If the user dismisses the picker, returns silently to
  /// [AuthInitial] without surfacing an error.
  Future<void> loginWithGoogle() async {
    emit(const AuthLoading());

    final GoogleAccountInfo? account;
    try {
      account = await _googleAuthService.signIn();
    } catch (_) {
      emit(const AuthError('Google sign-in failed. Please try again.'));
      return;
    }

    if (account == null) {
      // User cancelled the picker — no error, just reset.
      emit(const AuthInitial());
      return;
    }

    final result = await _loginWithGoogleUseCase(
      LoginWithGoogleParams(name: account.name, email: account.email),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (loginResult) => emit(AuthAuthenticated(loginResult.user)),
    );
  }

  /// Performs registration.
  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    emit(const AuthLoading());

    final result = await _registerUseCase(
      RegisterParams(name: name, email: email, password: password),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(AuthAuthenticated(user)),
    );
  }

  /// Completes sign-up via the `sign_up_form` endpoint. On success the access
  /// token is persisted locally and [SignUpSuccess] is emitted so the UI can
  /// route to OTP verification.
  Future<void> signUp({
    required String name,
    required String phoneNumber,
    required String countryCode,
    required String email,
    required String password,
    required String confirmPassword,
  }) async {
    emit(const AuthLoading());

    final result = await _signUpUseCase(
      SignUpParams(
        name: name,
        phoneNumber: phoneNumber,
        countryCode: countryCode,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
      ),
    );

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (signUpResult) => emit(SignUpSuccess(signUpResult)),
    );
  }

  /// Verifies the OTP entered by the user. Emits [OtpVerified] on success so the
  /// UI can route to the home shell, or [AuthError] with a readable message.
  Future<void> verifyOtp(String otp) async {
    emit(const OtpVerifying());

    final result = await _verifyOtpUseCase(VerifyOtpParams(otp: otp));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const OtpVerified()),
    );
  }

  /// Performs logout.
  Future<void> logout() async {
    emit(const AuthLoading());

    final result = await _logoutUseCase(const NoParams());

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}

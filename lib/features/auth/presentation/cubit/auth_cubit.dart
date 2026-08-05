import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/services/google_auth_service.dart';
import 'package:orko_hubco/core/services/push_notification_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_with_google_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/resend_otp_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/signup_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/verify_otp_usecase.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';

import '../../domain/usecases/logout_usecase.dart';

/// Auth Cubit — manages authentication state.
/// Depends only on use cases (domain layer), never on data layer directly.
class AuthCubit extends Cubit<AuthState> {
  final LoginUseCase _loginUseCase;
  final LoginWithGoogleUseCase _loginWithGoogleUseCase;
  final SignUpUseCase _signUpUseCase;
  final VerifyOtpUseCase _verifyOtpUseCase;
  final ResendOtpUseCase _resendOtpUseCase;
  final LogoutUseCase _logoutUseCase;
  final GoogleAuthService _googleAuthService;
  final PushNotificationService _pushNotificationService;
  final AnalyticsService _analytics;

  AuthCubit({
    required LoginUseCase loginUseCase,
    required LoginWithGoogleUseCase loginWithGoogleUseCase,
    required SignUpUseCase signUpUseCase,
    required VerifyOtpUseCase verifyOtpUseCase,
    required ResendOtpUseCase resendOtpUseCase,
    required LogoutUseCase logoutUseCase,
    required GoogleAuthService googleAuthService,
    required PushNotificationService pushNotificationService,
    required AnalyticsService analytics,
  })  : _loginUseCase = loginUseCase,
        _loginWithGoogleUseCase = loginWithGoogleUseCase,
        _signUpUseCase = signUpUseCase,
        _verifyOtpUseCase = verifyOtpUseCase,
        _resendOtpUseCase = resendOtpUseCase,
        _logoutUseCase = logoutUseCase,
        _googleAuthService = googleAuthService,
        _pushNotificationService = pushNotificationService,
        _analytics = analytics,
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
      (loginResult) {
        // Claim this device for the new session; the marker was cleared on the
        // last logout, so this re-registers the FCM token server-side.
        unawaited(_pushNotificationService.registerTokenForSession());
        _analytics.logEvent('login', parameters: {'method': 'phone'});
        emit(AuthAuthenticated(loginResult.user));
      },
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
      (loginResult) {
        unawaited(_pushNotificationService.registerTokenForSession());
        _analytics.logEvent('login', parameters: {'method': 'google'});
        emit(AuthAuthenticated(loginResult.user));
      },
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
      (signUpResult) {
        _analytics.logEvent('sign_up', parameters: {'method': 'phone'});
        emit(SignUpSuccess(signUpResult));
      },
    );
  }

  /// Verifies the OTP entered by the user. Emits [OtpVerified] on success so the
  /// UI can route to the home shell, or [AuthError] with a readable message.
  Future<void> verifyOtp(String otp) async {
    emit(const OtpVerifying());

    final result = await _verifyOtpUseCase(VerifyOtpParams(otp: otp));

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (_) {
        unawaited(_pushNotificationService.registerTokenForSession());
        emit(const OtpVerified());
      },
    );
  }

  /// Requests a fresh OTP. Emits [OtpResending] while in flight, then
  /// [OtpResent] (with the server's message) on success or [OtpResendFailure]
  /// on error. For the signup flow leave [otpId] null; for the sign-in flow
  /// pass the pending OTP id.
  Future<void> resendOtp({String? otpId}) async {
    emit(const OtpResending());

    final result = await _resendOtpUseCase(ResendOtpParams(otpId: otpId));

    result.fold(
      (failure) => emit(OtpResendFailure(failure.message)),
      (message) => emit(OtpResent(message)),
    );
  }

  /// Performs logout.
  Future<void> logout() async {
    emit(const AuthLoading());

    // Clear the device token server-side first, while the session is still
    // valid (the endpoint is auth'd). Best-effort — never blocks logout.
    await _pushNotificationService.unregisterTokenFromBackend();

    final result = await _logoutUseCase(const NoParams());

    result.fold(
      (failure) {
        // Logout failed — the user stays signed in, but the device token was
        // already deleted server-side above. Restore it so pushes keep working.
        unawaited(_pushNotificationService.registerTokenForSession());
        emit(AuthError(failure.message));
      },
      (_) => emit(const AuthUnauthenticated()),
    );
  }
}

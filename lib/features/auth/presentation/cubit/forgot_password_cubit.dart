import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/auth/domain/usecases/login_with_otp_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/verify_reset_otp_usecase.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/forgot_password_state.dart';

/// Drives the forgot-password flow (email → verify OTP → reset password),
/// independent of [AuthCubit] so it can't interfere with the login screen's
/// auth listener.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final LoginWithOtpUseCase _loginWithOtpUseCase;
  final VerifyResetOtpUseCase _verifyResetOtpUseCase;
  final ResetPasswordUseCase _resetPasswordUseCase;

  ForgotPasswordCubit({
    required LoginWithOtpUseCase loginWithOtpUseCase,
    required VerifyResetOtpUseCase verifyResetOtpUseCase,
    required ResetPasswordUseCase resetPasswordUseCase,
  })  : _loginWithOtpUseCase = loginWithOtpUseCase,
        _verifyResetOtpUseCase = verifyResetOtpUseCase,
        _resetPasswordUseCase = resetPasswordUseCase,
        super(const ForgotPasswordInitial());

  /// Step 1 — request an OTP for [email]. On success emits
  /// [ForgotPasswordOtpSent] with the issued otp id.
  Future<void> requestOtp(String email) async {
    if (state is ForgotPasswordSendingOtp) return;
    emit(const ForgotPasswordSendingOtp());

    final result = await _loginWithOtpUseCase(LoginWithOtpParams(email: email));

    if (isClosed) return;
    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (otpId) => emit(ForgotPasswordOtpSent(otpId: otpId, email: email)),
    );
  }

  /// Step 2 — verify the OTP. On success emits [ForgotPasswordOtpVerified] with
  /// the access token used to authorize the reset.
  Future<void> verifyOtp({required int otpId, required String otp}) async {
    if (state is ForgotPasswordVerifyingOtp) return;
    emit(const ForgotPasswordVerifyingOtp());

    final result = await _verifyResetOtpUseCase(
      VerifyResetOtpParams(otpId: otpId, otp: otp),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (accessToken) => emit(ForgotPasswordOtpVerified(accessToken)),
    );
  }

  /// Step 3 — set the new password, authorized with the [accessToken] from
  /// step 2.
  Future<void> resetPassword({
    required String accessToken,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state is ForgotPasswordResetting) return;
    emit(const ForgotPasswordResetting());

    final result = await _resetPasswordUseCase(
      ResetPasswordParams(
        accessToken: accessToken,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      ),
    );

    if (isClosed) return;
    result.fold(
      (failure) => emit(ForgotPasswordError(failure.message)),
      (message) => emit(ForgotPasswordSuccess(message)),
    );
  }
}

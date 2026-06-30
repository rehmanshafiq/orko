import 'package:equatable/equatable.dart';

/// States for the self-contained forgot-password flow:
/// email → verify OTP → reset password. The hosting sheet keeps the current
/// step, otp id, email and access token locally; the cubit only drives the
/// async work and these transient outcome states.
abstract class ForgotPasswordState extends Equatable {
  const ForgotPasswordState();

  @override
  List<Object?> get props => [];
}

class ForgotPasswordInitial extends ForgotPasswordState {
  const ForgotPasswordInitial();
}

/// Requesting the OTP (email step) is in flight.
class ForgotPasswordSendingOtp extends ForgotPasswordState {
  const ForgotPasswordSendingOtp();
}

/// The OTP was sent — carries the issued [otpId] and the [email] it went to.
class ForgotPasswordOtpSent extends ForgotPasswordState {
  const ForgotPasswordOtpSent({required this.otpId, required this.email});

  final int otpId;
  final String email;

  @override
  List<Object?> get props => [otpId, email];
}

/// Verifying the entered OTP is in flight.
class ForgotPasswordVerifyingOtp extends ForgotPasswordState {
  const ForgotPasswordVerifyingOtp();
}

/// The OTP was verified — carries the short-lived [accessToken] that authorizes
/// the password reset.
class ForgotPasswordOtpVerified extends ForgotPasswordState {
  const ForgotPasswordOtpVerified(this.accessToken);

  final String accessToken;

  @override
  List<Object?> get props => [accessToken];
}

/// The reset request is in flight.
class ForgotPasswordResetting extends ForgotPasswordState {
  const ForgotPasswordResetting();
}

/// Password reset succeeded — carries the server's confirmation message.
class ForgotPasswordSuccess extends ForgotPasswordState {
  const ForgotPasswordSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Something failed — carries a readable message for a snackbar. The hosting
/// sheet keeps its step/inputs so the user can retry.
class ForgotPasswordError extends ForgotPasswordState {
  const ForgotPasswordError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

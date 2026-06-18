import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/domain/entities/signup_result_entity.dart';

/// Data model for the complete-signup response `body`.
///
/// Expected shape:
/// ```json
/// {
///   "access": "<jwt>",
///   "user": { "id": 18008, "name": "Wayn", "email": "...", ... }
/// }
/// ```
class SignUpResultModel extends SignUpResultEntity {
  const SignUpResultModel({
    required super.accessToken,
    required super.user,
    super.otpVerificationRequired,
  });

  /// Parses the `body` object of the complete-signup response.
  factory SignUpResultModel.fromJson(Map<String, dynamic> body) {
    final rawUser = body['user'];
    final userMap = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : const <String, dynamic>{};

    final user = UserModel(
      id: userMap['id']?.toString() ?? '',
      email: userMap['email']?.toString() ?? '',
      name: userMap['name']?.toString() ?? '',
      avatarUrl: userMap['profile_img_url']?.toString(),
    );

    return SignUpResultModel(
      accessToken: body['access']?.toString() ?? '',
      user: user,
      otpVerificationRequired:
          userMap['otp_verification_required'] as bool? ?? false,
    );
  }
}

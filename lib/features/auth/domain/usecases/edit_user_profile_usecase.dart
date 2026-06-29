import 'package:equatable/equatable.dart';
import 'package:orko_hubco/core/error/failures.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';
import 'package:orko_hubco/features/auth/domain/repositories/auth_repository.dart';

/// Updates the user profile (`edit_user_profile`), then refreshes the cached
/// user via `get_user`. Returns the up-to-date [UserEntity].
class EditUserProfileUseCase
    implements UseCase<UserEntity, EditUserProfileParams> {
  final AuthRepository repository;

  const EditUserProfileUseCase(this.repository);

  @override
  Future<Either<Failure, UserEntity>> call(EditUserProfileParams params) {
    return repository.editUserProfile(params.toJson());
  }
}

/// Editable profile fields. Only name and phone number (with country code) can
/// be changed; email is read-only on the server side.
class EditUserProfileParams extends Equatable {
  const EditUserProfileParams({
    required this.name,
    this.phoneNumber,
    this.countryCode,
  });

  final String name;
  final String? phoneNumber;
  final String? countryCode;

  /// Builds the snake_case request body, omitting null/empty optional fields so
  /// the backend never receives blank overwrites.
  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name.trim(),
    };
    if (phoneNumber != null && phoneNumber!.trim().isNotEmpty) {
      map['phone_number'] = phoneNumber!.trim();
    }
    if (countryCode != null && countryCode!.trim().isNotEmpty) {
      map['country_code'] = countryCode!.trim();
    }
    return map;
  }

  @override
  List<Object?> get props => [name, phoneNumber, countryCode];
}

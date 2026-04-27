import 'package:equatable/equatable.dart';

/// Profile domain entity.
class ProfileEntity extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? avatarUrl;
  final String? bio;

  const ProfileEntity({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatarUrl,
    this.bio,
  });

  @override
  List<Object?> get props => [id, name, email, phone, avatarUrl, bio];
}

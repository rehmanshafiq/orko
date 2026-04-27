import 'package:equatable/equatable.dart';

/// Pure domain entity — no Flutter or serialization dependencies.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;
  final String? avatarUrl;
  final DateTime? createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, email, name, avatarUrl, createdAt];
}

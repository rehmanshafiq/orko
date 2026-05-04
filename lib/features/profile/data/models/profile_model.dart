import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';

/// Profile data model with JSON serialization.
class ProfileModel extends ProfileEntity {
  const ProfileModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    super.avatarUrl,
    super.bio,
  });

  /// Parses API or stub payloads; missing keys (e.g. Postman Echo) use safe defaults.
  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    final root = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    String pickStr(String key, String fallback) {
      final v = root[key];
      if (v == null) return fallback;
      if (v is String) return v.isEmpty ? fallback : v;
      return v.toString();
    }

    String? pickStrOpt(String key) {
      final v = root[key];
      if (v == null) return null;
      if (v is String) return v.isEmpty ? null : v;
      return v.toString();
    }

    return ProfileModel(
      id: pickStr('id', '1'),
      name: pickStr('name', 'Hubco Member'),
      email: pickStr('email', 'member@hubco.app'),
      phone: pickStrOpt('phone'),
      avatarUrl: pickStrOpt('avatar_url'),
      bio: pickStrOpt('bio'),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'avatar_url': avatarUrl,
      'bio': bio,
    };
  }
}

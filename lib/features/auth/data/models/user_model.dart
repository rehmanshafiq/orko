import 'package:orko_hubco/features/auth/domain/entities/user_entity.dart';

/// Data model with JSON serialization.
/// Extends the domain entity — adding serialization capabilities
/// without polluting the domain layer.
///
/// [fromJson]/[toJson] use the server's snake_case keys, so the same model
/// parses a raw API `user` object and round-trips through the local cache.
class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.email,
    required super.name,
    super.avatarUrl,
    super.createdAt,
    super.phoneNumber,
    super.countryCode,
    super.domain,
    super.tenant,
    super.appleEmail,
    super.address,
    super.verifiedAt,
    super.cityName,
    super.cityId,
    super.receiveSpecialOffers,
    super.otpVerificationRequired,
    super.isDummy,
    super.iotConnectivityStatus,
    super.testCustomer,
    super.isProfileComplete,
    super.vehicles,
    super.csmsVehicles,
    super.home,
    super.batteryMgmt,
    super.map,
    super.emissionSaving,
  });

  /// Creates a [UserModel] from a JSON map (API response or cached value).
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      // Accept the API key and the legacy cached key for backward compatibility.
      avatarUrl: (json['profile_img_url'] ?? json['avatar_url'])?.toString(),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      phoneNumber: json['phone_number']?.toString(),
      countryCode: json['country_code']?.toString(),
      domain: json['domain']?.toString(),
      tenant: _asInt(json['tenant']),
      appleEmail: json['apple_email']?.toString(),
      address: json['address']?.toString(),
      verifiedAt: json['verified_at']?.toString(),
      cityName: json['city_name']?.toString(),
      cityId: _asInt(json['city_id']),
      receiveSpecialOffers: json['receive_special_offers'] as bool? ?? false,
      otpVerificationRequired:
          json['otp_verification_required'] as bool? ?? false,
      isDummy: json['is_dummy'] as bool?,
      iotConnectivityStatus: json['iot_connectivity_status'] as bool? ?? false,
      testCustomer: json['test_customer'] as bool? ?? false,
      isProfileComplete: json['is_profile_complete'] as bool? ?? false,
      vehicles: json['vehicles'] is List
          ? List<dynamic>.from(json['vehicles'] as List)
          : const [],
      csmsVehicles: json['csms_vehicles'] is List
          ? List<dynamic>.from(json['csms_vehicles'] as List)
          : const [],
      home: json['home']?.toString(),
      batteryMgmt: json['battery_mgmt']?.toString(),
      map: json['map']?.toString(),
      emissionSaving: json['emission_saving']?.toString(),
    );
  }

  /// Converts this model to a JSON map (used for local caching).
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_img_url': avatarUrl,
      'created_at': createdAt?.toIso8601String(),
      'phone_number': phoneNumber,
      'country_code': countryCode,
      'domain': domain,
      'tenant': tenant,
      'apple_email': appleEmail,
      'address': address,
      'verified_at': verifiedAt,
      'city_name': cityName,
      'city_id': cityId,
      'receive_special_offers': receiveSpecialOffers,
      'otp_verification_required': otpVerificationRequired,
      'is_dummy': isDummy,
      'iot_connectivity_status': iotConnectivityStatus,
      'test_customer': testCustomer,
      'is_profile_complete': isProfileComplete,
      'vehicles': vehicles,
      'csms_vehicles': csmsVehicles,
      'home': home,
      'battery_mgmt': batteryMgmt,
      'map': map,
      'emission_saving': emissionSaving,
    };
  }

  /// Creates a copy with modified fields.
  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? avatarUrl,
    DateTime? createdAt,
    String? phoneNumber,
    String? countryCode,
    String? domain,
    int? tenant,
    String? appleEmail,
    String? address,
    String? verifiedAt,
    String? cityName,
    int? cityId,
    bool? receiveSpecialOffers,
    bool? otpVerificationRequired,
    bool? isDummy,
    bool? iotConnectivityStatus,
    bool? testCustomer,
    bool? isProfileComplete,
    List<dynamic>? vehicles,
    List<dynamic>? csmsVehicles,
    String? home,
    String? batteryMgmt,
    String? map,
    String? emissionSaving,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      countryCode: countryCode ?? this.countryCode,
      domain: domain ?? this.domain,
      tenant: tenant ?? this.tenant,
      appleEmail: appleEmail ?? this.appleEmail,
      address: address ?? this.address,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      cityName: cityName ?? this.cityName,
      cityId: cityId ?? this.cityId,
      receiveSpecialOffers: receiveSpecialOffers ?? this.receiveSpecialOffers,
      otpVerificationRequired:
          otpVerificationRequired ?? this.otpVerificationRequired,
      isDummy: isDummy ?? this.isDummy,
      iotConnectivityStatus:
          iotConnectivityStatus ?? this.iotConnectivityStatus,
      testCustomer: testCustomer ?? this.testCustomer,
      isProfileComplete: isProfileComplete ?? this.isProfileComplete,
      vehicles: vehicles ?? this.vehicles,
      csmsVehicles: csmsVehicles ?? this.csmsVehicles,
      home: home ?? this.home,
      batteryMgmt: batteryMgmt ?? this.batteryMgmt,
      map: map ?? this.map,
      emissionSaving: emissionSaving ?? this.emissionSaving,
    );
  }

  static int? _asInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }
}

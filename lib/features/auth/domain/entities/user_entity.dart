import 'package:equatable/equatable.dart';

/// Pure domain entity — no Flutter or serialization dependencies.
///
/// Mirrors the `user` object returned by the auth APIs so the full profile can
/// be cached and used to maintain the session.
class UserEntity extends Equatable {
  final String id;
  final String email;
  final String name;

  /// Profile image URL (maps to `profile_img_url`).
  final String? avatarUrl;
  final DateTime? createdAt;

  // ── Extended profile fields ───────────────────────────────────────────
  final String? phoneNumber;
  final String? countryCode;
  final String? domain;
  final int? tenant;
  final String? appleEmail;
  final String? address;
  final String? verifiedAt;
  final String? cityName;
  final int? cityId;
  final bool receiveSpecialOffers;
  final bool otpVerificationRequired;
  final bool? isDummy;
  final bool iotConnectivityStatus;
  final bool testCustomer;
  final bool isProfileComplete;
  final List<dynamic> vehicles;
  final List<dynamic> csmsVehicles;
  final String? home;
  final String? batteryMgmt;
  final String? map;
  final String? emissionSaving;

  const UserEntity({
    required this.id,
    required this.email,
    required this.name,
    this.avatarUrl,
    this.createdAt,
    this.phoneNumber,
    this.countryCode,
    this.domain,
    this.tenant,
    this.appleEmail,
    this.address,
    this.verifiedAt,
    this.cityName,
    this.cityId,
    this.receiveSpecialOffers = false,
    this.otpVerificationRequired = false,
    this.isDummy,
    this.iotConnectivityStatus = false,
    this.testCustomer = false,
    this.isProfileComplete = false,
    this.vehicles = const [],
    this.csmsVehicles = const [],
    this.home,
    this.batteryMgmt,
    this.map,
    this.emissionSaving,
  });

  @override
  List<Object?> get props => [
        id,
        email,
        name,
        avatarUrl,
        createdAt,
        phoneNumber,
        countryCode,
        domain,
        tenant,
        appleEmail,
        address,
        verifiedAt,
        cityName,
        cityId,
        receiveSpecialOffers,
        otpVerificationRequired,
        isDummy,
        iotConnectivityStatus,
        testCustomer,
        isProfileComplete,
        vehicles,
        csmsVehicles,
        home,
        batteryMgmt,
        map,
        emissionSaving,
      ];
}

import 'package:equatable/equatable.dart';

/// Strongly-typed representation of the app's remote configuration.
///
/// JSON shape (source of truth):
/// ```json
/// {
///   "api_constants": {
///     "base_url_live": "https://apis-py.orkofleet.com/",
///     "base_url_qa": "https://staging-python.orkofleet.com/",
///     "domain": "Hubco",
///     "api_endpoints": {
///       "charging_station_map": "api/v1/charging-station/nearest?",
///       "charging_station_detail": "api/v1/charging-station/",
///       "sign_up_form": "api/v1/orko-auth/complete-signup",
///       "verify_otp": "api/v1/orko-auth/verify-otp",
///       "login_api": "api/v1/orko-auth/login-with-password",
///       "login_with_google": "api/v1/orko-auth/login-with-google"
///     }
///   }
/// }
/// ```
class RemoteConfigModel extends Equatable {
  const RemoteConfigModel({required this.apiConstants});

  final ApiConstants apiConstants;

  /// Parses the FULL config map (the object containing `api_constants`).
  ///
  /// Used for the GetStorage cache and the bundled asset, both of which store
  /// the complete wrapper object.
  factory RemoteConfigModel.fromJson(Map<String, dynamic> json) {
    final rawApiConstants = json['api_constants'];
    return RemoteConfigModel(
      apiConstants: ApiConstants.fromJson(
        rawApiConstants is Map
            ? Map<String, dynamic>.from(rawApiConstants)
            : const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'api_constants': apiConstants.toJson()};
  }

  RemoteConfigModel copyWith({ApiConstants? apiConstants}) {
    return RemoteConfigModel(apiConstants: apiConstants ?? this.apiConstants);
  }

  @override
  List<Object?> get props => [apiConstants];
}

/// API constants section of the remote config.
class ApiConstants extends Equatable {
  const ApiConstants({
    required this.baseUrlLive,
    required this.baseUrlQa,
    required this.domain,
    required this.apiEndpoints,
  });

  final String baseUrlLive;
  final String baseUrlQa;
  final String domain;
  final ApiEndpoints apiEndpoints;

  /// Parses the inner `api_constants` object. This matches the value stored in
  /// the Firebase Remote Config `api_constants` parameter.
  factory ApiConstants.fromJson(Map<String, dynamic> json) {
    final rawEndpoints = json['api_endpoints'];
    return ApiConstants(
      baseUrlLive: json['base_url_live'] as String? ?? '',
      baseUrlQa: json['base_url_qa'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      apiEndpoints: ApiEndpoints.fromJson(
        rawEndpoints is Map
            ? Map<String, dynamic>.from(rawEndpoints)
            : const <String, dynamic>{},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'base_url_live': baseUrlLive,
      'base_url_qa': baseUrlQa,
      'domain': domain,
      'api_endpoints': apiEndpoints.toJson(),
    };
  }

  ApiConstants copyWith({
    String? baseUrlLive,
    String? baseUrlQa,
    String? domain,
    ApiEndpoints? apiEndpoints,
  }) {
    return ApiConstants(
      baseUrlLive: baseUrlLive ?? this.baseUrlLive,
      baseUrlQa: baseUrlQa ?? this.baseUrlQa,
      domain: domain ?? this.domain,
      apiEndpoints: apiEndpoints ?? this.apiEndpoints,
    );
  }

  @override
  List<Object?> get props => [baseUrlLive, baseUrlQa, domain, apiEndpoints];
}

/// API endpoint paths section of the remote config.
class ApiEndpoints extends Equatable {
  const ApiEndpoints({
    required this.chargingStationMap,
    required this.chargingStationDetail,
    required this.signUpForm,
    required this.verifyOtp,
    required this.loginApi,
    required this.loginWithGoogle,
  });

  final String chargingStationMap;
  final String chargingStationDetail;
  final String signUpForm;
  final String verifyOtp;
  final String loginApi;
  final String loginWithGoogle;

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    return ApiEndpoints(
      chargingStationMap: json['charging_station_map'] as String? ?? '',
      chargingStationDetail: json['charging_station_detail'] as String? ?? '',
      signUpForm: json['sign_up_form'] as String? ?? '',
      verifyOtp: json['verify_otp'] as String? ?? '',
      loginApi: json['login_api'] as String? ?? '',
      loginWithGoogle: json['login_with_google'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charging_station_map': chargingStationMap,
      'charging_station_detail': chargingStationDetail,
      'sign_up_form': signUpForm,
      'verify_otp': verifyOtp,
      'login_api': loginApi,
      'login_with_google': loginWithGoogle,
    };
  }

  ApiEndpoints copyWith({
    String? chargingStationMap,
    String? chargingStationDetail,
    String? signUpForm,
    String? verifyOtp,
    String? loginApi,
    String? loginWithGoogle,
  }) {
    return ApiEndpoints(
      chargingStationMap: chargingStationMap ?? this.chargingStationMap,
      chargingStationDetail: chargingStationDetail ?? this.chargingStationDetail,
      signUpForm: signUpForm ?? this.signUpForm,
      verifyOtp: verifyOtp ?? this.verifyOtp,
      loginApi: loginApi ?? this.loginApi,
      loginWithGoogle: loginWithGoogle ?? this.loginWithGoogle,
    );
  }

  @override
  List<Object?> get props => [
    chargingStationMap,
    chargingStationDetail,
    signUpForm,
    verifyOtp,
    loginApi,
    loginWithGoogle,
  ];
}

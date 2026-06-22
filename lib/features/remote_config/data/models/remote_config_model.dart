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
    required this.chargingStationFavourites,
    required this.signUpForm,
    required this.verifyOtp,
    required this.resendOtp,
    required this.loginApi,
    required this.loginWithGoogle,
    required this.logoutApi,
    required this.chargerDetails,
    required this.bookingSlots,
    required this.createBooking,
    required this.createBookingHgl,
    required this.myBookings,
    required this.cancelBooking,
    required this.rescheduleBooking,
    required this.chargeSessionHistory,
    required this.vehicleMakes,
    required this.vehicleModels,
    required this.addVehicle,
    required this.deleteVehicle,
    required this.userVehicles,
    required this.chargerCompatibility,
  });

  final String chargingStationMap;
  final String chargingStationDetail;
  final String chargingStationFavourites;
  final String signUpForm;
  final String verifyOtp;
  final String resendOtp;
  final String loginApi;
  final String loginWithGoogle;
  final String logoutApi;
  final String chargerDetails;
  final String bookingSlots;
  final String createBooking;
  final String createBookingHgl;
  final String myBookings;
  final String cancelBooking;
  final String rescheduleBooking;
  final String chargeSessionHistory;
  final String vehicleMakes;
  final String vehicleModels;
  final String addVehicle;
  final String deleteVehicle;
  final String userVehicles;
  final String chargerCompatibility;

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    return ApiEndpoints(
      chargingStationMap: json['charging_station_map'] as String? ?? '',
      chargingStationDetail: json['charging_station_detail'] as String? ?? '',
      chargingStationFavourites:
          json['charging_station_favourites'] as String? ?? '',
      signUpForm: json['sign_up_form'] as String? ?? '',
      verifyOtp: json['verify_otp'] as String? ?? '',
      resendOtp: json['resend_otp'] as String? ?? '',
      loginApi: json['login_api'] as String? ?? '',
      loginWithGoogle: json['login_with_google'] as String? ?? '',
      logoutApi: json['logout_api'] as String? ?? '',
      chargerDetails: json['charger_details'] as String? ?? '',
      bookingSlots: json['booking_slots'] as String? ?? '',
      createBooking: json['create_booking'] as String? ?? '',
      createBookingHgl: json['create_booking_hgl'] as String? ?? '',
      myBookings: json['my_bookings'] as String? ?? '',
      cancelBooking: json['cancel_booking'] as String? ?? '',
      rescheduleBooking: json['reschedule_booking'] as String? ?? '',
      chargeSessionHistory: json['charge_session_history'] as String? ?? '',
      vehicleMakes: json['vehicle_makes'] as String? ?? '',
      vehicleModels: json['vehicle_models'] as String? ?? '',
      addVehicle: json['add_vehicle'] as String? ?? '',
      deleteVehicle: json['delete_vehicle'] as String? ?? '',
      userVehicles: json['user_vehicles'] as String? ?? '',
      chargerCompatibility: json['charger_compatibility'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charging_station_map': chargingStationMap,
      'charging_station_detail': chargingStationDetail,
      'charging_station_favourites': chargingStationFavourites,
      'sign_up_form': signUpForm,
      'verify_otp': verifyOtp,
      'resend_otp': resendOtp,
      'login_api': loginApi,
      'login_with_google': loginWithGoogle,
      'logout_api': logoutApi,
      'charger_details': chargerDetails,
      'booking_slots': bookingSlots,
      'create_booking': createBooking,
      'create_booking_hgl': createBookingHgl,
      'my_bookings': myBookings,
      'cancel_booking': cancelBooking,
      'reschedule_booking': rescheduleBooking,
      'charge_session_history': chargeSessionHistory,
      'vehicle_makes': vehicleMakes,
      'vehicle_models': vehicleModels,
      'add_vehicle': addVehicle,
      'delete_vehicle': deleteVehicle,
      'user_vehicles': userVehicles,
      'charger_compatibility': chargerCompatibility,
    };
  }

  ApiEndpoints copyWith({
    String? chargingStationMap,
    String? chargingStationDetail,
    String? chargingStationFavourites,
    String? signUpForm,
    String? verifyOtp,
    String? resendOtp,
    String? loginApi,
    String? loginWithGoogle,
    String? logoutApi,
    String? chargerDetails,
    String? bookingSlots,
    String? createBooking,
    String? createBookingHgl,
    String? myBookings,
    String? cancelBooking,
    String? rescheduleBooking,
    String? chargeSessionHistory,
    String? vehicleMakes,
    String? vehicleModels,
    String? addVehicle,
    String? deleteVehicle,
    String? userVehicles,
    String? chargerCompatibility,
  }) {
    return ApiEndpoints(
      chargingStationMap: chargingStationMap ?? this.chargingStationMap,
      chargingStationDetail: chargingStationDetail ?? this.chargingStationDetail,
      chargingStationFavourites:
          chargingStationFavourites ?? this.chargingStationFavourites,
      signUpForm: signUpForm ?? this.signUpForm,
      verifyOtp: verifyOtp ?? this.verifyOtp,
      resendOtp: resendOtp ?? this.resendOtp,
      loginApi: loginApi ?? this.loginApi,
      loginWithGoogle: loginWithGoogle ?? this.loginWithGoogle,
      logoutApi: logoutApi ?? this.logoutApi,
      chargerDetails: chargerDetails ?? this.chargerDetails,
      bookingSlots: bookingSlots ?? this.bookingSlots,
      createBooking: createBooking ?? this.createBooking,
      createBookingHgl: createBookingHgl ?? this.createBookingHgl,
      myBookings: myBookings ?? this.myBookings,
      cancelBooking: cancelBooking ?? this.cancelBooking,
      rescheduleBooking: rescheduleBooking ?? this.rescheduleBooking,
      chargeSessionHistory: chargeSessionHistory ?? this.chargeSessionHistory,
      vehicleMakes: vehicleMakes ?? this.vehicleMakes,
      vehicleModels: vehicleModels ?? this.vehicleModels,
      addVehicle: addVehicle ?? this.addVehicle,
      deleteVehicle: deleteVehicle ?? this.deleteVehicle,
      userVehicles: userVehicles ?? this.userVehicles,
      chargerCompatibility: chargerCompatibility ?? this.chargerCompatibility,
    );
  }

  @override
  List<Object?> get props => [
    chargingStationMap,
    chargingStationDetail,
    chargingStationFavourites,
    signUpForm,
    verifyOtp,
    resendOtp,
    loginApi,
    loginWithGoogle,
    logoutApi,
    chargerDetails,
    bookingSlots,
    createBooking,
    createBookingHgl,
    myBookings,
    cancelBooking,
    rescheduleBooking,
    chargeSessionHistory,
    vehicleMakes,
    vehicleModels,
    addVehicle,
    deleteVehicle,
    userVehicles,
    chargerCompatibility,
  ];
}

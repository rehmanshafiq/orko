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
///     "google_places_api_key": "AIza...",
///     "autocomplete_url": "https://maps.googleapis.com/maps/api/place/autocomplete/json",
///     "details_url": "https://maps.googleapis.com/maps/api/place/details/json",
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
    required this.googlePlacesApiKey,
    required this.autocompleteUrl,
    required this.detailsUrl,
    required this.apiEndpoints,
  });

  final String baseUrlLive;
  final String baseUrlQa;
  final String domain;
  final String googlePlacesApiKey;
  final String autocompleteUrl;
  final String detailsUrl;
  final ApiEndpoints apiEndpoints;

  /// Parses the inner `api_constants` object. This matches the value stored in
  /// the Firebase Remote Config `api_constants` parameter.
  factory ApiConstants.fromJson(Map<String, dynamic> json) {
    final rawEndpoints = json['api_endpoints'];
    return ApiConstants(
      baseUrlLive: json['base_url_live'] as String? ?? '',
      baseUrlQa: json['base_url_qa'] as String? ?? '',
      domain: json['domain'] as String? ?? '',
      googlePlacesApiKey: json['google_places_api_key'] as String? ?? '',
      autocompleteUrl: json['autocomplete_url'] as String? ?? '',
      detailsUrl: json['details_url'] as String? ?? '',
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
      'google_places_api_key': googlePlacesApiKey,
      'autocomplete_url': autocompleteUrl,
      'details_url': detailsUrl,
      'api_endpoints': apiEndpoints.toJson(),
    };
  }

  ApiConstants copyWith({
    String? baseUrlLive,
    String? baseUrlQa,
    String? domain,
    String? googlePlacesApiKey,
    String? autocompleteUrl,
    String? detailsUrl,
    ApiEndpoints? apiEndpoints,
  }) {
    return ApiConstants(
      baseUrlLive: baseUrlLive ?? this.baseUrlLive,
      baseUrlQa: baseUrlQa ?? this.baseUrlQa,
      domain: domain ?? this.domain,
      googlePlacesApiKey: googlePlacesApiKey ?? this.googlePlacesApiKey,
      autocompleteUrl: autocompleteUrl ?? this.autocompleteUrl,
      detailsUrl: detailsUrl ?? this.detailsUrl,
      apiEndpoints: apiEndpoints ?? this.apiEndpoints,
    );
  }

  @override
  List<Object?> get props => [
        baseUrlLive,
        baseUrlQa,
        domain,
        googlePlacesApiKey,
        autocompleteUrl,
        detailsUrl,
        apiEndpoints,
      ];
}

/// API endpoint paths section of the remote config.
class ApiEndpoints extends Equatable {
  const ApiEndpoints({
    required this.chargingStationMap,
    required this.chargingStationFilterOptions,
    required this.chargingStationDetail,
    required this.chargingStationFavourites,
    required this.chargingStationSearch,
    required this.chargingStationPopular,
    required this.signUpForm,
    required this.verifyOtp,
    required this.resendOtp,
    required this.loginApi,
    required this.loginWithGoogle,
    required this.loginWithOtp,
    required this.resetPassword,
    required this.logoutApi,
    required this.deleteAccount,
    required this.getUser,
    required this.editUserProfile,
    required this.uploadUserPicture,
    required this.chargerDetails,
    required this.bookingSlots,
    required this.createBooking,
    required this.createBookingHgl,
    required this.myBookings,
    required this.cancelBooking,
    required this.rescheduleBooking,
    required this.verifyQr,
    required this.chargeSessionHistory,
    required this.liveSession,
    required this.chargingStats,
    required this.vehicleMakes,
    required this.vehicleModels,
    required this.addVehicle,
    required this.deleteVehicle,
    required this.userVehicles,
    required this.chargerCompatibility,
    required this.tripPlanningVehicles,
    required this.planTrip,
    required this.saveTrip,
    required this.savedTrips,
    required this.savedTripDetail,
    required this.notifications,
    required this.notificationsUnreadCount,
    required this.notificationsMarkAllRead,
    required this.notificationsPreferences,
    required this.notificationsDeviceToken,
  });

  final String chargingStationMap;
  final String chargingStationFilterOptions;
  final String chargingStationDetail;
  final String chargingStationFavourites;
  final String chargingStationSearch;
  final String chargingStationPopular;
  final String signUpForm;
  final String verifyOtp;
  final String resendOtp;
  final String loginApi;
  final String loginWithGoogle;
  final String loginWithOtp;
  final String resetPassword;
  final String logoutApi;
  final String deleteAccount;
  final String getUser;
  final String editUserProfile;
  final String uploadUserPicture;
  final String chargerDetails;
  final String bookingSlots;
  final String createBooking;
  final String createBookingHgl;
  final String myBookings;
  final String cancelBooking;
  final String rescheduleBooking;
  final String verifyQr;
  final String chargeSessionHistory;
  final String liveSession;
  final String chargingStats;
  final String vehicleMakes;
  final String vehicleModels;
  final String addVehicle;
  final String deleteVehicle;
  final String userVehicles;
  final String chargerCompatibility;
  final String tripPlanningVehicles;
  final String planTrip;
  final String saveTrip;
  final String savedTrips;
  final String savedTripDetail;
  final String notifications;
  final String notificationsUnreadCount;
  final String notificationsMarkAllRead;
  final String notificationsPreferences;
  final String notificationsDeviceToken;

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    return ApiEndpoints(
      chargingStationMap: json['charging_station_map'] as String? ?? '',
      chargingStationFilterOptions:
          json['charging_station_filter_options'] as String? ?? '',
      chargingStationDetail: json['charging_station_detail'] as String? ?? '',
      chargingStationFavourites:
          json['charging_station_favourites'] as String? ?? '',
      chargingStationSearch: json['charging_station_search'] as String? ?? '',
      chargingStationPopular: json['charging_station_popular'] as String? ?? '',
      signUpForm: json['sign_up_form'] as String? ?? '',
      verifyOtp: json['verify_otp'] as String? ?? '',
      resendOtp: json['resend_otp'] as String? ?? '',
      loginApi: json['login_api'] as String? ?? '',
      loginWithGoogle: json['login_with_google'] as String? ?? '',
      loginWithOtp: json['login_with_otp'] as String? ?? '',
      resetPassword: json['reset_password'] as String? ?? '',
      logoutApi: json['logout_api'] as String? ?? '',
      deleteAccount: json['delete_account'] as String? ?? '',
      getUser: json['get_user'] as String? ?? '',
      editUserProfile: json['edit_user_profile'] as String? ?? '',
      uploadUserPicture: json['upload_user_picture'] as String? ?? '',
      chargerDetails: json['charger_details'] as String? ?? '',
      bookingSlots: json['booking_slots'] as String? ?? '',
      createBooking: json['create_booking'] as String? ?? '',
      createBookingHgl: json['create_booking_hgl'] as String? ?? '',
      myBookings: json['my_bookings'] as String? ?? '',
      cancelBooking: json['cancel_booking'] as String? ?? '',
      rescheduleBooking: json['reschedule_booking'] as String? ?? '',
      verifyQr: json['verify_qr'] as String? ?? '',
      chargeSessionHistory: json['charge_session_history'] as String? ?? '',
      liveSession: json['live_session'] as String? ?? '',
      chargingStats: json['charging_stats'] as String? ?? '',
      vehicleMakes: json['vehicle_makes'] as String? ?? '',
      vehicleModels: json['vehicle_models'] as String? ?? '',
      addVehicle: json['add_vehicle'] as String? ?? '',
      deleteVehicle: json['delete_vehicle'] as String? ?? '',
      userVehicles: json['user_vehicles'] as String? ?? '',
      chargerCompatibility: json['charger_compatibility'] as String? ?? '',
      tripPlanningVehicles: json['trip_planning_vehicles'] as String? ?? '',
      planTrip: json['plan_trip'] as String? ?? '',
      saveTrip: json['save_trip'] as String? ?? '',
      savedTrips: json['saved_trips'] as String? ?? '',
      savedTripDetail: json['saved_trip_detail'] as String? ?? '',
      notifications: json['notifications'] as String? ?? '',
      notificationsUnreadCount:
          json['notifications_unread_count'] as String? ?? '',
      notificationsMarkAllRead:
          json['notifications_mark_all_read'] as String? ?? '',
      notificationsPreferences:
          json['notifications_preferences'] as String? ?? '',
      notificationsDeviceToken:
          json['notifications_device_token'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charging_station_map': chargingStationMap,
      'charging_station_filter_options': chargingStationFilterOptions,
      'charging_station_detail': chargingStationDetail,
      'charging_station_favourites': chargingStationFavourites,
      'charging_station_search': chargingStationSearch,
      'charging_station_popular': chargingStationPopular,
      'sign_up_form': signUpForm,
      'verify_otp': verifyOtp,
      'resend_otp': resendOtp,
      'login_api': loginApi,
      'login_with_google': loginWithGoogle,
      'login_with_otp': loginWithOtp,
      'reset_password': resetPassword,
      'logout_api': logoutApi,
      'delete_account': deleteAccount,
      'get_user': getUser,
      'edit_user_profile': editUserProfile,
      'upload_user_picture': uploadUserPicture,
      'charger_details': chargerDetails,
      'booking_slots': bookingSlots,
      'create_booking': createBooking,
      'create_booking_hgl': createBookingHgl,
      'my_bookings': myBookings,
      'cancel_booking': cancelBooking,
      'reschedule_booking': rescheduleBooking,
      'verify_qr': verifyQr,
      'charge_session_history': chargeSessionHistory,
      'live_session': liveSession,
      'charging_stats': chargingStats,
      'vehicle_makes': vehicleMakes,
      'vehicle_models': vehicleModels,
      'add_vehicle': addVehicle,
      'delete_vehicle': deleteVehicle,
      'user_vehicles': userVehicles,
      'charger_compatibility': chargerCompatibility,
      'trip_planning_vehicles': tripPlanningVehicles,
      'plan_trip': planTrip,
      'save_trip': saveTrip,
      'saved_trips': savedTrips,
      'saved_trip_detail': savedTripDetail,
      'notifications': notifications,
      'notifications_unread_count': notificationsUnreadCount,
      'notifications_mark_all_read': notificationsMarkAllRead,
      'notifications_preferences': notificationsPreferences,
      'notifications_device_token': notificationsDeviceToken,
    };
  }

  ApiEndpoints copyWith({
    String? chargingStationMap,
    String? chargingStationFilterOptions,
    String? chargingStationDetail,
    String? chargingStationFavourites,
    String? chargingStationSearch,
    String? chargingStationPopular,
    String? signUpForm,
    String? verifyOtp,
    String? resendOtp,
    String? loginApi,
    String? loginWithGoogle,
    String? loginWithOtp,
    String? resetPassword,
    String? logoutApi,
    String? deleteAccount,
    String? getUser,
    String? editUserProfile,
    String? uploadUserPicture,
    String? chargerDetails,
    String? bookingSlots,
    String? createBooking,
    String? createBookingHgl,
    String? myBookings,
    String? cancelBooking,
    String? rescheduleBooking,
    String? verifyQr,
    String? chargeSessionHistory,
    String? liveSession,
    String? chargingStats,
    String? vehicleMakes,
    String? vehicleModels,
    String? addVehicle,
    String? deleteVehicle,
    String? userVehicles,
    String? chargerCompatibility,
    String? tripPlanningVehicles,
    String? planTrip,
    String? saveTrip,
    String? savedTrips,
    String? savedTripDetail,
    String? notifications,
    String? notificationsUnreadCount,
    String? notificationsMarkAllRead,
    String? notificationsPreferences,
    String? notificationsDeviceToken,
  }) {
    return ApiEndpoints(
      chargingStationMap: chargingStationMap ?? this.chargingStationMap,
      chargingStationFilterOptions:
          chargingStationFilterOptions ?? this.chargingStationFilterOptions,
      chargingStationDetail: chargingStationDetail ?? this.chargingStationDetail,
      chargingStationFavourites:
          chargingStationFavourites ?? this.chargingStationFavourites,
      chargingStationSearch:
          chargingStationSearch ?? this.chargingStationSearch,
      chargingStationPopular:
          chargingStationPopular ?? this.chargingStationPopular,
      signUpForm: signUpForm ?? this.signUpForm,
      verifyOtp: verifyOtp ?? this.verifyOtp,
      resendOtp: resendOtp ?? this.resendOtp,
      loginApi: loginApi ?? this.loginApi,
      loginWithGoogle: loginWithGoogle ?? this.loginWithGoogle,
      loginWithOtp: loginWithOtp ?? this.loginWithOtp,
      resetPassword: resetPassword ?? this.resetPassword,
      logoutApi: logoutApi ?? this.logoutApi,
      deleteAccount: deleteAccount ?? this.deleteAccount,
      getUser: getUser ?? this.getUser,
      editUserProfile: editUserProfile ?? this.editUserProfile,
      uploadUserPicture: uploadUserPicture ?? this.uploadUserPicture,
      chargerDetails: chargerDetails ?? this.chargerDetails,
      bookingSlots: bookingSlots ?? this.bookingSlots,
      createBooking: createBooking ?? this.createBooking,
      createBookingHgl: createBookingHgl ?? this.createBookingHgl,
      myBookings: myBookings ?? this.myBookings,
      cancelBooking: cancelBooking ?? this.cancelBooking,
      rescheduleBooking: rescheduleBooking ?? this.rescheduleBooking,
      verifyQr: verifyQr ?? this.verifyQr,
      chargeSessionHistory: chargeSessionHistory ?? this.chargeSessionHistory,
      liveSession: liveSession ?? this.liveSession,
      chargingStats: chargingStats ?? this.chargingStats,
      vehicleMakes: vehicleMakes ?? this.vehicleMakes,
      vehicleModels: vehicleModels ?? this.vehicleModels,
      addVehicle: addVehicle ?? this.addVehicle,
      deleteVehicle: deleteVehicle ?? this.deleteVehicle,
      userVehicles: userVehicles ?? this.userVehicles,
      chargerCompatibility: chargerCompatibility ?? this.chargerCompatibility,
      tripPlanningVehicles: tripPlanningVehicles ?? this.tripPlanningVehicles,
      planTrip: planTrip ?? this.planTrip,
      saveTrip: saveTrip ?? this.saveTrip,
      savedTrips: savedTrips ?? this.savedTrips,
      savedTripDetail: savedTripDetail ?? this.savedTripDetail,
      notifications: notifications ?? this.notifications,
      notificationsUnreadCount:
          notificationsUnreadCount ?? this.notificationsUnreadCount,
      notificationsMarkAllRead:
          notificationsMarkAllRead ?? this.notificationsMarkAllRead,
      notificationsPreferences:
          notificationsPreferences ?? this.notificationsPreferences,
      notificationsDeviceToken:
          notificationsDeviceToken ?? this.notificationsDeviceToken,
    );
  }

  @override
  List<Object?> get props => [
    chargingStationMap,
    chargingStationFilterOptions,
    chargingStationDetail,
    chargingStationFavourites,
    chargingStationSearch,
    chargingStationPopular,
    signUpForm,
    verifyOtp,
    resendOtp,
    loginApi,
    loginWithGoogle,
    loginWithOtp,
    resetPassword,
    logoutApi,
    deleteAccount,
    getUser,
    editUserProfile,
    uploadUserPicture,
    chargerDetails,
    bookingSlots,
    createBooking,
    createBookingHgl,
    myBookings,
    cancelBooking,
    rescheduleBooking,
    verifyQr,
    chargeSessionHistory,
    liveSession,
    chargingStats,
    vehicleMakes,
    vehicleModels,
    addVehicle,
    deleteVehicle,
    userVehicles,
    chargerCompatibility,
    tripPlanningVehicles,
    planTrip,
    saveTrip,
    savedTrips,
    savedTripDetail,
    notifications,
    notificationsUnreadCount,
    notificationsMarkAllRead,
    notificationsPreferences,
    notificationsDeviceToken,
  ];
}

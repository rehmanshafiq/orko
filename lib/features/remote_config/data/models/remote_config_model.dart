import 'package:equatable/equatable.dart';

/// Strongly-typed representation of the app's remote configuration.
///
/// JSON shape (source of truth):
/// ```json
/// {
///   "api_constants": {
///     "base_url_live": "https://apis-py.orkofleet.com/",
///     "base_url_qa": "https://staging-python.orkofleet.com/",
///     "api_endpoints": {
///       "charging_station_map": "api/v1/charging-station/nearest?",
///       "charging_station_detail": "api/v1/charging-station/"
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
    required this.apiEndpoints,
  });

  final String baseUrlLive;
  final String baseUrlQa;
  final ApiEndpoints apiEndpoints;

  /// Parses the inner `api_constants` object. This matches the value stored in
  /// the Firebase Remote Config `api_constants` parameter.
  factory ApiConstants.fromJson(Map<String, dynamic> json) {
    final rawEndpoints = json['api_endpoints'];
    return ApiConstants(
      baseUrlLive: json['base_url_live'] as String? ?? '',
      baseUrlQa: json['base_url_qa'] as String? ?? '',
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
      'api_endpoints': apiEndpoints.toJson(),
    };
  }

  ApiConstants copyWith({
    String? baseUrlLive,
    String? baseUrlQa,
    ApiEndpoints? apiEndpoints,
  }) {
    return ApiConstants(
      baseUrlLive: baseUrlLive ?? this.baseUrlLive,
      baseUrlQa: baseUrlQa ?? this.baseUrlQa,
      apiEndpoints: apiEndpoints ?? this.apiEndpoints,
    );
  }

  @override
  List<Object?> get props => [baseUrlLive, baseUrlQa, apiEndpoints];
}

/// API endpoint paths section of the remote config.
class ApiEndpoints extends Equatable {
  const ApiEndpoints({
    required this.chargingStationMap,
    required this.chargingStationDetail,
  });

  final String chargingStationMap;
  final String chargingStationDetail;

  factory ApiEndpoints.fromJson(Map<String, dynamic> json) {
    return ApiEndpoints(
      chargingStationMap: json['charging_station_map'] as String? ?? '',
      chargingStationDetail: json['charging_station_detail'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'charging_station_map': chargingStationMap,
      'charging_station_detail': chargingStationDetail,
    };
  }

  ApiEndpoints copyWith({
    String? chargingStationMap,
    String? chargingStationDetail,
  }) {
    return ApiEndpoints(
      chargingStationMap: chargingStationMap ?? this.chargingStationMap,
      chargingStationDetail: chargingStationDetail ?? this.chargingStationDetail,
    );
  }

  @override
  List<Object?> get props => [chargingStationMap, chargingStationDetail];
}

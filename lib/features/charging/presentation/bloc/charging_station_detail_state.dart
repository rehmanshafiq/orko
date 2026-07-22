import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/charging/presentation/models/amenity_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/review_model.dart';

enum ChargingDetailStatus { initial, loading, success, failure }

class ChargingStationDetailState extends Equatable {
  const ChargingStationDetailState({
    this.status = ChargingDetailStatus.initial,
    this.errorMessage = '',
    this.favorite = false,
    this.favoriteLoading = false,
    this.favoriteError = '',
    this.favoriteEventId = 0,
    this.locationId,
    this.selectedPortIndex = 0,
    this.ports = const [],
    this.amenities = const [],
    this.reviews = const [],
    this.name = '',
    this.address = '',
    this.operatingHours = '',
    this.openingTime = '',
    this.closingTime = '',
    this.pricing = '',
    this.contactNumber = '',
    this.averageRating = 0,
    this.totalReviews = 0,
    this.distance = 0,
    this.latitude,
    this.longitude,
    this.chargePointId,
    this.isClosed = false,
    this.bannerImage,
  });

  final ChargingDetailStatus status;
  final String errorMessage;

  final bool favorite;

  /// True while a favourite add/remove request is in flight.
  final bool favoriteLoading;

  /// Transient error message for a failed favourite toggle. Pair with
  /// [favoriteEventId] so the UI can react to repeated identical failures.
  final String favoriteError;

  /// Bumped on every favourite toggle outcome so a [BlocListener] fires even
  /// when the message text is unchanged.
  final int favoriteEventId;

  /// The station's location id, used as `location_id` for the favourite APIs.
  final int? locationId;

  final int selectedPortIndex;
  final List<ChargerPortModel> ports;
  final List<AmenityModel> amenities;
  final List<ReviewModel> reviews;

  final String name;
  final String address;
  final String operatingHours;

  /// Raw `HH:mm:ss` opening time from the detail API (for booking slot checks).
  final String openingTime;

  /// Raw `HH:mm:ss` closing time from the detail API (for booking slot checks).
  final String closingTime;

  final String pricing;
  final String contactNumber;
  final double averageRating;
  final int totalReviews;
  /// Distance from the requesting device, in meters (`distance` API key).
  final double distance;

  /// Station coordinates from the detail API (`location.lat` / `location.long`).
  final double? latitude;
  final double? longitude;

  /// The station's primary `charge_point_id`, used for the vehicle
  /// compatibility check before booking. Null when the API omits it.
  final String? chargePointId;

  /// True when the station is closed (`is_closed` API key) — booking shows a
  /// "Coming soon" toast instead of proceeding.
  final bool isClosed;

  /// Station banner image URL (`banner_image` API key). Null when the backend
  /// omits it, in which case the bundled asset is shown.
  final String? bannerImage;

  bool get isLoading => status == ChargingDetailStatus.loading;
  bool get isFailure => status == ChargingDetailStatus.failure;
  bool get isSuccess => status == ChargingDetailStatus.success;

  ChargingStationDetailState copyWith({
    ChargingDetailStatus? status,
    String? errorMessage,
    bool? favorite,
    bool? favoriteLoading,
    String? favoriteError,
    int? favoriteEventId,
    int? locationId,
    int? selectedPortIndex,
    List<ChargerPortModel>? ports,
    List<AmenityModel>? amenities,
    List<ReviewModel>? reviews,
    String? name,
    String? address,
    String? operatingHours,
    String? openingTime,
    String? closingTime,
    String? pricing,
    String? contactNumber,
    double? averageRating,
    int? totalReviews,
    double? distance,
    double? latitude,
    double? longitude,
    String? chargePointId,
    bool? isClosed,
    String? bannerImage,
  }) {
    return ChargingStationDetailState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      favorite: favorite ?? this.favorite,
      favoriteLoading: favoriteLoading ?? this.favoriteLoading,
      favoriteError: favoriteError ?? this.favoriteError,
      favoriteEventId: favoriteEventId ?? this.favoriteEventId,
      locationId: locationId ?? this.locationId,
      selectedPortIndex: selectedPortIndex ?? this.selectedPortIndex,
      ports: ports ?? this.ports,
      amenities: amenities ?? this.amenities,
      reviews: reviews ?? this.reviews,
      name: name ?? this.name,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      openingTime: openingTime ?? this.openingTime,
      closingTime: closingTime ?? this.closingTime,
      pricing: pricing ?? this.pricing,
      contactNumber: contactNumber ?? this.contactNumber,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      distance: distance ?? this.distance,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      chargePointId: chargePointId ?? this.chargePointId,
      isClosed: isClosed ?? this.isClosed,
      bannerImage: bannerImage ?? this.bannerImage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        favorite,
        favoriteLoading,
        favoriteError,
        favoriteEventId,
        locationId,
        selectedPortIndex,
        ports,
        amenities,
        reviews,
        name,
        address,
        operatingHours,
        openingTime,
        closingTime,
        pricing,
        contactNumber,
        averageRating,
        totalReviews,
        distance,
        latitude,
        longitude,
        chargePointId,
        isClosed,
        bannerImage,
      ];
}

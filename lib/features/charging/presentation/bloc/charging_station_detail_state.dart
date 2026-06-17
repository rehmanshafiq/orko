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
    this.selectedPortIndex = 0,
    this.ports = const [],
    this.amenities = const [],
    this.reviews = const [],
    this.name = '',
    this.address = '',
    this.operatingHours = '',
    this.pricing = '',
    this.contactNumber = '',
    this.averageRating = 0,
    this.totalReviews = 0,
    this.distance = 0,
  });

  final ChargingDetailStatus status;
  final String errorMessage;

  final bool favorite;
  final int selectedPortIndex;
  final List<ChargerPortModel> ports;
  final List<AmenityModel> amenities;
  final List<ReviewModel> reviews;

  final String name;
  final String address;
  final String operatingHours;
  final String pricing;
  final String contactNumber;
  final double averageRating;
  final int totalReviews;
  /// Distance from the requesting device, in meters (`distance` API key).
  final double distance;

  bool get isLoading => status == ChargingDetailStatus.loading;
  bool get isFailure => status == ChargingDetailStatus.failure;
  bool get isSuccess => status == ChargingDetailStatus.success;

  ChargingStationDetailState copyWith({
    ChargingDetailStatus? status,
    String? errorMessage,
    bool? favorite,
    int? selectedPortIndex,
    List<ChargerPortModel>? ports,
    List<AmenityModel>? amenities,
    List<ReviewModel>? reviews,
    String? name,
    String? address,
    String? operatingHours,
    String? pricing,
    String? contactNumber,
    double? averageRating,
    int? totalReviews,
    double? distance,
  }) {
    return ChargingStationDetailState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      favorite: favorite ?? this.favorite,
      selectedPortIndex: selectedPortIndex ?? this.selectedPortIndex,
      ports: ports ?? this.ports,
      amenities: amenities ?? this.amenities,
      reviews: reviews ?? this.reviews,
      name: name ?? this.name,
      address: address ?? this.address,
      operatingHours: operatingHours ?? this.operatingHours,
      pricing: pricing ?? this.pricing,
      contactNumber: contactNumber ?? this.contactNumber,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      distance: distance ?? this.distance,
    );
  }

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        favorite,
        selectedPortIndex,
        ports,
        amenities,
        reviews,
        name,
        address,
        operatingHours,
        pricing,
        contactNumber,
        averageRating,
        totalReviews,
        distance,
      ];
}

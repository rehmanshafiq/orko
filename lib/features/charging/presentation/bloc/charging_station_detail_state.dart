import 'package:equatable/equatable.dart';
import 'package:orko_hubco/features/charging/presentation/models/amenity_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/review_model.dart';

class ChargingStationDetailState extends Equatable {
  const ChargingStationDetailState({
    required this.favorite,
    required this.selectedPortIndex,
    required this.ports,
    required this.amenities,
    required this.reviews,
  });

  final bool favorite;
  final int selectedPortIndex;
  final List<ChargerPortModel> ports;
  final List<AmenityModel> amenities;
  final List<ReviewModel> reviews;

  ChargingStationDetailState copyWith({
    bool? favorite,
    int? selectedPortIndex,
    List<ChargerPortModel>? ports,
    List<AmenityModel>? amenities,
    List<ReviewModel>? reviews,
  }) {
    return ChargingStationDetailState(
      favorite: favorite ?? this.favorite,
      selectedPortIndex: selectedPortIndex ?? this.selectedPortIndex,
      ports: ports ?? this.ports,
      amenities: amenities ?? this.amenities,
      reviews: reviews ?? this.reviews,
    );
  }

  @override
  List<Object?> get props => [
        favorite,
        selectedPortIndex,
        ports,
        amenities,
        reviews,
      ];
}

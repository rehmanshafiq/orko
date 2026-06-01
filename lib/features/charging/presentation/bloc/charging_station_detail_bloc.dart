import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_event.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_state.dart';
import 'package:orko_hubco/features/charging/presentation/models/amenity_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/review_model.dart';

class ChargingStationDetailBloc
    extends Bloc<ChargingStationDetailEvent, ChargingStationDetailState> {
  ChargingStationDetailBloc()
      : super(
          ChargingStationDetailState(
            favorite: false,
            selectedPortIndex: _indexOfFirstAvailablePort(_kPorts),
            ports: _kPorts,
            amenities: _kAmenities,
            reviews: _kReviews,
          ),
        ) {
    on<ChargingStationDetailFavoriteToggled>(_onFavoriteToggled);
    on<ChargingStationDetailPortSelected>(_onPortSelected);
  }

  static const List<ChargerPortModel> _kPorts = [
    ChargerPortModel(label: 'CCS, 150 kW', price: 'Rs 45 per kWh', available: true),
    ChargerPortModel(
      label: 'CHAdeMO, 150 kW',
      price: 'Rs 45 per kWh',
      available: false,
    ),
    ChargerPortModel(label: 'Type 2, 22 kW', price: 'Rs 38 per kWh', available: true),
  ];

  static const List<AmenityModel> _kAmenities = [
    AmenityModel(Icons.wifi_rounded, 'WiFi'),
    AmenityModel(Icons.wc_rounded, 'Restroom'),
    AmenityModel(Icons.local_cafe_rounded, 'Cafe'),
    AmenityModel(Icons.local_parking_rounded, 'Parking'),
    AmenityModel(Icons.schedule_rounded, '24 Hours'),
  ];

  static const List<ReviewModel> _kReviews = [
    ReviewModel(
      name: 'Ali S.',
      text: 'Fast charging and clean location. Highly recommend!',
      rating: 5,
    ),
    ReviewModel(
      name: 'Ayesha K.',
      text: 'Easy to find on M2. Staff was helpful.',
      rating: 4,
    ),
    ReviewModel(
      name: 'Omar M.',
      text: 'Good rates compared to other hubs nearby.',
      rating: 5,
    ),
  ];

  /// Highlighted port row — only available ports may be selected.
  static int _indexOfFirstAvailablePort(List<ChargerPortModel> ports) {
    for (var i = 0; i < ports.length; i++) {
      if (ports[i].available) return i;
    }
    return 0;
  }

  void _onFavoriteToggled(
    ChargingStationDetailFavoriteToggled event,
    Emitter<ChargingStationDetailState> emit,
  ) {
    emit(state.copyWith(favorite: !state.favorite));
  }

  void _onPortSelected(
    ChargingStationDetailPortSelected event,
    Emitter<ChargingStationDetailState> emit,
  ) {
    final i = event.index;
    if (i < 0 || i >= state.ports.length) return;
    final port = state.ports[i];
    if (!port.available) return;
    emit(state.copyWith(selectedPortIndex: i));
  }
}

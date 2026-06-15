import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/features/charging/domain/entities/charging_station_detail_entity.dart';
import 'package:orko_hubco/features/charging/domain/usecases/get_charging_station_detail_usecase.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_event.dart';
import 'package:orko_hubco/features/charging/presentation/bloc/charging_station_detail_state.dart';
import 'package:orko_hubco/features/charging/presentation/models/amenity_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/charger_port_model.dart';
import 'package:orko_hubco/features/charging/presentation/models/review_model.dart';

class ChargingStationDetailBloc
    extends Bloc<ChargingStationDetailEvent, ChargingStationDetailState> {
  ChargingStationDetailBloc({
    required GetChargingStationDetailUseCase getStationDetailUseCase,
  })  : _getStationDetailUseCase = getStationDetailUseCase,
        super(const ChargingStationDetailState()) {
    on<ChargingStationDetailRequested>(_onRequested);
    on<ChargingStationDetailFavoriteToggled>(_onFavoriteToggled);
    on<ChargingStationDetailPortSelected>(_onPortSelected);
  }

  final GetChargingStationDetailUseCase _getStationDetailUseCase;

  Future<void> _onRequested(
    ChargingStationDetailRequested event,
    Emitter<ChargingStationDetailState> emit,
  ) async {
    emit(state.copyWith(
      status: ChargingDetailStatus.loading,
      errorMessage: '',
    ));

    final result = await _getStationDetailUseCase(
      ChargingStationDetailParams(
        stationId: event.stationId,
        latitude: event.latitude,
        longitude: event.longitude,
      ),
    );

    result.fold(
      (failure) => emit(state.copyWith(
        status: ChargingDetailStatus.failure,
        errorMessage: failure.message,
      )),
      (detail) {
        final ports = _mapPorts(detail);
        emit(state.copyWith(
          status: ChargingDetailStatus.success,
          ports: ports,
          amenities: _mapAmenities(detail),
          reviews: _mapReviews(detail),
          selectedPortIndex: _indexOfFirstAvailablePort(ports),
          name: detail.name,
          address: detail.address,
          operatingHours: _formatOperatingHours(detail),
          pricing: _formatPricing(detail),
          contactNumber: detail.contactNumber,
          averageRating: detail.averageRating,
          totalReviews: detail.totalReviews,
          distanceKm: detail.distance / 1000,
        ));
      },
    );
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
    if (!state.ports[i].available) return;
    emit(state.copyWith(selectedPortIndex: i));
  }

  // ── Mapping helpers ─────────────────────────────────────────────────────

  List<ChargerPortModel> _mapPorts(ChargingStationDetailEntity detail) {
    return detail.connectors
        .map(
          (c) => ChargerPortModel(
            label: _portLabel(c),
            price: _connectorPrice(c.price),
            available: c.isAvailable,
          ),
        )
        .toList(growable: false);
  }

  String _portLabel(ConnectorEntity connector) {
    final type = connector.connectorType.trim();
    final power = connector.power.trim();
    final parts = <String>[
      if (type.isNotEmpty) type,
      if (power.isNotEmpty) '$power kW',
    ];
    return parts.isEmpty ? 'Connector' : parts.join(', ');
  }

  String _connectorPrice(ConnectorPriceEntity? price) {
    if (price == null) return 'Price not available';
    final amount = price.price == price.price.roundToDouble()
        ? price.price.toStringAsFixed(0)
        : price.price.toStringAsFixed(2);
    final currency = price.currency.trim();
    final mode = _prettyLabel(price.pricingMode);
    final buffer = StringBuffer();
    if (currency.isNotEmpty) buffer.write('$currency ');
    buffer.write(amount);
    if (mode.isNotEmpty) buffer.write(' • $mode');
    return buffer.toString();
  }

  List<AmenityModel> _mapAmenities(ChargingStationDetailEntity detail) {
    return detail.amenities
        .map((a) => AmenityModel(label: a.name, imageUrl: a.imageUrl))
        .toList(growable: false);
  }

  List<ReviewModel> _mapReviews(ChargingStationDetailEntity detail) {
    return detail.reviews
        .map((r) => ReviewModel(name: r.name, text: r.text, rating: r.rating))
        .toList(growable: false);
  }

  String _formatOperatingHours(ChargingStationDetailEntity detail) {
    final open = _formatTime(detail.openingTime);
    final close = _formatTime(detail.closingTime);
    if (open.isEmpty && close.isEmpty) return 'Not available';
    if (open.isEmpty) return close;
    if (close.isEmpty) return open;
    return '$open - $close';
  }

  /// Trims a `HH:mm:ss` time string down to `HH:mm`.
  String _formatTime(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    final parts = value.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return value;
  }

  String _formatPricing(ChargingStationDetailEntity detail) {
    for (final connector in detail.connectors) {
      if (connector.price != null) {
        return _connectorPrice(connector.price);
      }
    }
    return 'Not available';
  }

  /// `time_duration` → `Time Duration`.
  String _prettyLabel(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    return value
        .split(RegExp(r'[_\s]+'))
        .where((w) => w.isNotEmpty)
        .map((w) => w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  static int _indexOfFirstAvailablePort(List<ChargerPortModel> ports) {
    for (var i = 0; i < ports.length; i++) {
      if (ports[i].available) return i;
    }
    return 0;
  }
}

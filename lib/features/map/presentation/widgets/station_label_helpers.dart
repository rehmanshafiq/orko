import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// Pure formatting helpers shared by the home and filter station cards.

String stationDistanceLabel(HubcoLocationEntity station) =>
    AppHelpers.formatDistanceKm(station.distance);

/// Card title from the API `area`/`city`, e.g. `HGL – F11, Islamabad`.
/// Empty when neither is provided (the card then falls back to the name).
String stationLocationLabel(HubcoLocationEntity station) {
  final parts = [station.area, station.city].where((s) => s.isNotEmpty);
  if (parts.isEmpty) return '';
  return 'HGL – ${parts.join(', ')}';
}

String stationAvailabilityLabel(HubcoLocationEntity station) {
  final total = station.numberOfConnectors;
  if (total <= 0) return '—';
  return '${station.availableConnectors}/$total Available';
}

/// Peak power(s) formatted like `60 kW` (joins multiple with `/`). Empty when
/// the API sent no `power` values.
String stationPowerLabel(HubcoLocationEntity station) {
  if (station.powerOutputs.isEmpty) return '';
  final parts = station.powerOutputs.map((p) =>
      p == p.roundToDouble() ? p.toStringAsFixed(0) : p.toStringAsFixed(1));
  return '${parts.join('/')} kW';
}

String stationPriceLabel(HubcoLocationEntity station) {
  if (station.prices.isEmpty) return '—';

  final price = station.prices.first;
  final amount = price.price == price.price.roundToDouble()
      ? price.price.toStringAsFixed(0)
      : price.price.toStringAsFixed(2);
  final currency = price.currency.trim();
  final mode = price.pricingMode.trim().toLowerCase();

  final buffer = StringBuffer();
  if (currency.isNotEmpty) {
    buffer.write(currency == 'PKR' ? 'Rs' : currency);
    buffer.write(' ');
  }
  buffer.write(amount);
  if (mode == 'kwh') {
    buffer.write('/kWh');
  } else if (mode.isNotEmpty) {
    buffer.write('/');
    buffer.write(mode.replaceAll('_', ' '));
  }
  return buffer.toString();
}

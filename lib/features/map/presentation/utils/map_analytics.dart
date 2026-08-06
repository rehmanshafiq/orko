import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// Logs a `station_detail_view` analytics event for [station].
///
/// [source] identifies where the open originated (e.g. `map_marker`,
/// `nearby_list`, `home_results`). `distance_km` is rounded to one decimal so
/// the parameter stays low-cardinality for GA4.
void logStationDetailView(
  HubcoLocationEntity station, {
  required String source,
}) {
  sl<AnalyticsService>().logEvent('station_detail_view', parameters: {
    'station_id': station.id,
    'source': source,
    'distance_km': (station.distance * 10).round() / 10,
  });
}

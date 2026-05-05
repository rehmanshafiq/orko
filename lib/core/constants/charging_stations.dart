import 'dart:math' as math;

import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';

/// A geographic point with an optional human-readable name.
///
/// Used by the trip planner to describe the start/end points of a route
/// (which are typed cities, not stations) in the same shape as a station.
class GeoPoint {
  const GeoPoint({
    required this.name,
    required this.latitude,
    required this.longitude,
  });

  final String name;
  final double latitude;
  final double longitude;
}

/// Static catalogue of HUBCO charging stations and route-planning helpers.
///
/// The [all] list mirrors the API response served by the backend so the
/// trip-planner can work fully offline / without a network round-trip while
/// the real cubit is still being wired in.
class HubcoChargingStations {
  HubcoChargingStations._();

  /// Full list of available HUBCO charging stations.
  static const List<HubcoLocationEntity> all = <HubcoLocationEntity>[
    HubcoLocationEntity(
      id: 46,
      name: 'HGL - APL Dandewal (N)',
      address: 'Painsra Service Area (North) - M-4',
      latitude: 31.34959,
      longitude: 72.79716,
      status: true,
    ),
    HubcoLocationEntity(
      id: 47,
      name: 'HGL - APL Dandewal (S)',
      address: 'Painsra Service Area (South) - M-4',
      latitude: 31.3487,
      longitude: 72.79834,
      status: true,
    ),
    HubcoLocationEntity(
      id: 42,
      name: 'HGL - APL Hakla (N)',
      address: 'Hakla Service Area (North) - M-1',
      latitude: 33.63213,
      longitude: 72.84182,
      status: true,
    ),
    HubcoLocationEntity(
      id: 43,
      name: 'HGL - APL Hakla (S)',
      address: 'Hakla Service Area (South) - M-1',
      latitude: 33.62584,
      longitude: 72.84782,
      status: true,
    ),
    HubcoLocationEntity(
      id: 28,
      name: 'HGL - PARCO Gulberg',
      address: 'MM ALam RD Lahore',
      latitude: 31.5057917,
      longitude: 74.3490074,
      status: true,
    ),
    HubcoLocationEntity(
      id: 32,
      name: 'HGL - PSO Alfalah',
      address: 'HGL - PSO Alfalah, N-5',
      latitude: 25.41644,
      longitude: 68.33912,
      status: true,
    ),
    HubcoLocationEntity(
      id: 34,
      name: 'HGL - PSO Bedal',
      address: 'HGL - PSO Bedal, N-5',
      latitude: 27.668496,
      longitude: 68.92955,
      status: true,
    ),
    HubcoLocationEntity(
      id: 45,
      name: 'HGL - PSO Multan Petroleum Service (S)',
      address: 'Multan Service Area (South) - M-5',
      latitude: 29.99486,
      longitude: 71.38793,
      status: true,
    ),
    HubcoLocationEntity(
      id: 33,
      name: 'HGL - PSO New Ali',
      address: 'HGL - PSO New Ali, N-5',
      latitude: 26.69339,
      longitude: 68.027244,
      status: true,
    ),
    HubcoLocationEntity(
      id: 44,
      name: 'HGL - PSO Shershah Petroleum Service (N)',
      address: 'Multan Service Area (North) - M-5',
      latitude: 29.99688,
      longitude: 71.38619,
      status: true,
    ),
    HubcoLocationEntity(
      id: 35,
      name: 'HGL - PSO Zahir Pir (N)',
      address: 'HGL - PSO Zahir Pir (N), M-5',
      latitude: 28.922335,
      longitude: 70.622736,
      status: true,
    ),
    HubcoLocationEntity(
      id: 39,
      name: 'HGL - PSO Zahir Pir (S)',
      address: 'Zahir Pir Service Area (South), M-5',
      latitude: 28.92008,
      longitude: 70.62385,
      status: true,
    ),
    HubcoLocationEntity(
      id: 31,
      name: 'HGL APL Model Filling Station',
      address: 'F11, Islamabad',
      latitude: 33.685339,
      longitude: 72.985836,
      status: true,
    ),
    HubcoLocationEntity(
      id: 27,
      name: 'HGL Ocean Mall',
      address: 'Block 9 Clifton, Karachi, 75600, Pakistan',
      latitude: 24.8238165,
      longitude: 67.0355302,
      status: true,
    ),
    HubcoLocationEntity(
      id: 24,
      name: 'HGL PSO BTL',
      address:
          'Plot No, 103/A Canal Gardens Main Rd, Executive Lodges Sector B Bahria Town, Lahore, 53720',
      latitude: 31.3847868,
      longitude: 74.1688703,
      status: true,
    ),
    HubcoLocationEntity(
      id: 29,
      name: 'HGL PSO Magic River',
      address:
          'River Ravi Bridge, Lahore-Islamabad Mtwy, Bhadru Lahore, Pakistan',
      latitude: 31.5457958,
      longitude: 74.2552617,
      status: true,
    ),
    HubcoLocationEntity(
      id: 23,
      name: 'HGL PSO Marwat',
      address: 'M39G+6WC, Rehman Baba Rd, I-8/3 I 8 Markaz I-8, Islamabad',
      latitude: 33.668058,
      longitude: 73.077261,
      status: true,
    ),
    HubcoLocationEntity(
      id: 22,
      name: 'HGL PSO Q-Star',
      address:
          'Q Star, Main Korangi Rd, opposite CSD, D.H.A. Phase 1 Karachi Cantonment, Karachi, 75500',
      latitude: 24.8530476,
      longitude: 67.0528612,
      status: true,
    ),
    HubcoLocationEntity(
      id: 30,
      name: 'HGL Zeta Mall',
      address:
          'Main G.T. Rd, opposite DHA 2, Zaraj Housing Society Sector A, Islamabad',
      latitude: 33.519817,
      longitude: 73.158801,
      status: true,
    ),
    HubcoLocationEntity(
      id: 41,
      name: 'METRO Safari Store Gulshan-e-Iqbal',
      address:
          '190-219, OKEWARI, NA-Class, Main University Rd, near Safari Park, Gulshan-e-Iqbal, Karachi, 73500, Pakistan',
      latitude: 24.92115,
      longitude: 67.10563,
      status: true,
    ),
  ];

  /// Approximate centroids for the most common Pakistani cities the user can
  /// type into the trip-planner. Lookup is case-insensitive substring based,
  /// so "Karachi", "karachi", "Karachi, PK" all resolve to the same point.
  static const Map<String, GeoPoint> _cities = <String, GeoPoint>{
    'karachi': GeoPoint(name: 'Karachi', latitude: 24.8607, longitude: 67.0011),
    'hyderabad':
        GeoPoint(name: 'Hyderabad', latitude: 25.3960, longitude: 68.3578),
    'sukkur': GeoPoint(name: 'Sukkur', latitude: 27.7058, longitude: 68.8483),
    'rahim yar khan': GeoPoint(
        name: 'Rahim Yar Khan', latitude: 28.4202, longitude: 70.2952),
    'bahawalpur':
        GeoPoint(name: 'Bahawalpur', latitude: 29.3956, longitude: 71.6722),
    'multan': GeoPoint(name: 'Multan', latitude: 30.1575, longitude: 71.5249),
    'sahiwal': GeoPoint(name: 'Sahiwal', latitude: 30.6682, longitude: 73.1114),
    'faisalabad':
        GeoPoint(name: 'Faisalabad', latitude: 31.4504, longitude: 73.1350),
    'lahore': GeoPoint(name: 'Lahore', latitude: 31.5497, longitude: 74.3436),
    'gujranwala':
        GeoPoint(name: 'Gujranwala', latitude: 32.1877, longitude: 74.1945),
    'sialkot': GeoPoint(name: 'Sialkot', latitude: 32.4945, longitude: 74.5229),
    'rawalpindi':
        GeoPoint(name: 'Rawalpindi', latitude: 33.5651, longitude: 73.0169),
    'islamabad':
        GeoPoint(name: 'Islamabad', latitude: 33.6844, longitude: 73.0479),
    'peshawar':
        GeoPoint(name: 'Peshawar', latitude: 34.0151, longitude: 71.5249),
    'quetta': GeoPoint(name: 'Quetta', latitude: 30.1798, longitude: 66.9750),
  };

  /// Resolves an arbitrary user-typed city / address to a [GeoPoint].
  ///
  /// Falls back to a station that *contains* the typed text in its name or
  /// address. Returns `null` if nothing matches.
  static GeoPoint? resolveCity(String input) {
    final query = input.trim().toLowerCase();
    if (query.isEmpty) return null;

    final exact = _cities[query];
    if (exact != null) return exact;

    for (final entry in _cities.entries) {
      if (query.contains(entry.key) || entry.key.contains(query)) {
        return entry.value;
      }
    }

    for (final station in all) {
      final hay = '${station.name} ${station.address}'.toLowerCase();
      if (hay.contains(query)) {
        return GeoPoint(
          name: station.name,
          latitude: station.latitude,
          longitude: station.longitude,
        );
      }
    }
    return null;
  }

  /// Great-circle distance in kilometres between two coordinates.
  static double distanceKm(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLng = _toRadians(lng2 - lng1);
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  /// Perpendicular (cross-track) distance in kilometres of point `p` to the
  /// great-circle line that passes through `a` -> `b`.
  static double crossTrackKm({
    required double aLat,
    required double aLng,
    required double bLat,
    required double bLng,
    required double pLat,
    required double pLng,
  }) {
    const earthRadiusKm = 6371.0;
    final delta13 = distanceKm(aLat, aLng, pLat, pLng) / earthRadiusKm;
    final theta13 = _bearing(aLat, aLng, pLat, pLng);
    final theta12 = _bearing(aLat, aLng, bLat, bLng);
    final dxt = math.asin(math.sin(delta13) * math.sin(theta13 - theta12));
    return (dxt * earthRadiusKm).abs();
  }

  /// Returns charging stations roughly *along* the corridor between
  /// (`startLat`,`startLng`) and (`endLat`,`endLng`), sorted by distance from
  /// the start. At most [maxStops] stations are returned, evenly spaced along
  /// the corridor so the user gets a representative subset for the route.
  static List<HubcoLocationEntity> stopsAlongRoute({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
    required int maxStops,
    double corridorKm = 80,
  }) {
    if (maxStops <= 0) return const [];

    final totalRouteKm =
        distanceKm(startLat, startLng, endLat, endLng);
    if (totalRouteKm < 1) return const [];

    final candidates = <_StationOnRoute>[];
    for (final station in all) {
      if (!station.status) continue;
      final cross = crossTrackKm(
        aLat: startLat,
        aLng: startLng,
        bLat: endLat,
        bLng: endLng,
        pLat: station.latitude,
        pLng: station.longitude,
      );
      if (cross > corridorKm) continue;

      final fromStart =
          distanceKm(startLat, startLng, station.latitude, station.longitude);
      final fromEnd =
          distanceKm(endLat, endLng, station.latitude, station.longitude);

      if (fromStart > totalRouteKm + corridorKm) continue;
      if (fromEnd > totalRouteKm + corridorKm) continue;

      candidates.add(_StationOnRoute(
        station: station,
        distanceFromStartKm: fromStart,
      ));
    }

    candidates.sort(
      (a, b) => a.distanceFromStartKm.compareTo(b.distanceFromStartKm),
    );

    final deduped = _dedupeNearby(candidates, minSeparationKm: 25);

    if (deduped.length <= maxStops) {
      return deduped.map((e) => e.station).toList();
    }

    final picked = <_StationOnRoute>[];
    for (var i = 1; i <= maxStops; i++) {
      final targetKm = totalRouteKm * (i / (maxStops + 1));
      _StationOnRoute? best;
      double bestDelta = double.infinity;
      for (final c in deduped) {
        if (picked.contains(c)) continue;
        final delta = (c.distanceFromStartKm - targetKm).abs();
        if (delta < bestDelta) {
          bestDelta = delta;
          best = c;
        }
      }
      if (best != null) picked.add(best);
    }
    picked.sort(
      (a, b) => a.distanceFromStartKm.compareTo(b.distanceFromStartKm),
    );
    return picked.map((e) => e.station).toList();
  }

  static List<_StationOnRoute> _dedupeNearby(
    List<_StationOnRoute> sorted, {
    required double minSeparationKm,
  }) {
    final result = <_StationOnRoute>[];
    for (final c in sorted) {
      final tooClose = result.any((kept) =>
          (kept.distanceFromStartKm - c.distanceFromStartKm).abs() <
          minSeparationKm);
      if (!tooClose) result.add(c);
    }
    return result;
  }

  static double _toRadians(double degrees) => degrees * (math.pi / 180.0);

  static double _bearing(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    final phi1 = _toRadians(lat1);
    final phi2 = _toRadians(lat2);
    final lambda1 = _toRadians(lng1);
    final lambda2 = _toRadians(lng2);
    final y = math.sin(lambda2 - lambda1) * math.cos(phi2);
    final x = math.cos(phi1) * math.sin(phi2) -
        math.sin(phi1) * math.cos(phi2) * math.cos(lambda2 - lambda1);
    return math.atan2(y, x);
  }
}

class _StationOnRoute {
  _StationOnRoute({
    required this.station,
    required this.distanceFromStartKm,
  });

  final HubcoLocationEntity station;
  final double distanceFromStartKm;
}

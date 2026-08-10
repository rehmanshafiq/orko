/// The two tabs shown once a trip is planned: the enroute charging stops the
/// planner recommends, and the full list of every charger along the route.
enum TripStopsTab { suggested, all }

extension TripStopsTabX on TripStopsTab {
  String get label {
    switch (this) {
      case TripStopsTab.suggested:
        return 'Recommended Stops';
      case TripStopsTab.all:
        return 'All Stops';
    }
  }
}

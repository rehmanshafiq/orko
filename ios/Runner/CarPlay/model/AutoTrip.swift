import Foundation

/// Sanitized, display-only saved-trip data from the Dart bridge
/// (`getSavedTrips` / `getSavedTripDetail`). Trip/stop info only — no vehicle
/// registration, user id, or other PII.
///
/// The same type serves both the list row (summary fields; [stops] empty) and
/// the detail view (with [stops] populated).
struct AutoTrip {
    let id: Int
    let title: String
    let originAddress: String?
    let destinationAddress: String?
    let totalDistanceKm: Double?
    let totalDriveMinutes: Double?
    let totalChargingMinutes: Double?
    let totalCost: Double?
    let currency: String
    let stopCount: Int
    let stops: [AutoTripStop]

    static func from(_ m: [String: Any]) -> AutoTrip {
        let stops = (ChannelValue.list(m["stops"]) ?? []).compactMap(ChannelValue.map).map(AutoTripStop.from)
        return AutoTrip(
            id: ChannelValue.int(m["id"]) ?? -1,
            title: ChannelValue.string(m["title"]) ?? "",
            originAddress: ChannelValue.string(m["originAddress"]),
            destinationAddress: ChannelValue.string(m["destinationAddress"]),
            totalDistanceKm: ChannelValue.double(m["totalDistanceKm"]),
            totalDriveMinutes: ChannelValue.double(m["totalDriveMinutes"]),
            totalChargingMinutes: ChannelValue.double(m["totalChargingMinutes"]),
            totalCost: ChannelValue.double(m["totalCost"]),
            currency: ChannelValue.string(m["currency"]) ?? "",
            stopCount: ChannelValue.int(m["stopCount"]) ?? stops.count,
            stops: stops
        )
    }

    /// Parses the `trips` array out of a `getSavedTrips` result map.
    static func listFrom(_ result: [String: Any]) -> [AutoTrip] {
        (ChannelValue.list(result["trips"]) ?? []).compactMap(ChannelValue.map).map(from)
    }

    /// Parses the `trip` object out of a `getSavedTripDetail` result map.
    static func detailFrom(_ result: [String: Any]) -> AutoTrip? {
        ChannelValue.map(result["trip"]).map(from)
    }
}

/// A single charging stop on a saved trip (display-only).
struct AutoTripStop {
    let sequence: Int
    let locationName: String
    let locationAddress: String?
    let lat: Double?
    let lng: Double?
    let connectorType: String
    let powerKw: Double?
    let arrivalSoc: Double?
    let departureSoc: Double?
    let chargingMinutes: Double?
    let cost: Double?

    static func from(_ m: [String: Any]) -> AutoTripStop {
        AutoTripStop(
            sequence: ChannelValue.int(m["sequence"]) ?? 0,
            locationName: ChannelValue.string(m["locationName"]) ?? "",
            locationAddress: ChannelValue.string(m["locationAddress"]),
            lat: ChannelValue.double(m["lat"]),
            lng: ChannelValue.double(m["lng"]),
            connectorType: ChannelValue.string(m["connectorType"]) ?? "",
            powerKw: ChannelValue.double(m["powerKw"]),
            arrivalSoc: ChannelValue.double(m["arrivalSoc"]),
            departureSoc: ChannelValue.double(m["departureSoc"]),
            chargingMinutes: ChannelValue.double(m["chargingMinutes"]),
            cost: ChannelValue.double(m["cost"])
        )
    }
}

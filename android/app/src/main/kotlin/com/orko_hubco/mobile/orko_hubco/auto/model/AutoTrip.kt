package com.orko_hubco.mobile.orko_hubco.auto.model

/**
 * Sanitized, display-only saved-trip data from the Dart bridge
 * (`getSavedTrips` / `getSavedTripDetail`). Trip/stop info only — no vehicle
 * registration, user id, or other PII.
 *
 * The same class serves both the list row (summary fields; [stops] empty) and
 * the detail view (with [stops] populated).
 */
data class AutoTrip(
    val id: Int,
    val title: String,
    val originAddress: String?,
    val destinationAddress: String?,
    val totalDistanceKm: Double?,
    val totalDriveMinutes: Double?,
    val totalChargingMinutes: Double?,
    val totalCost: Double?,
    val currency: String,
    val stopCount: Int,
    val stops: List<AutoTripStop>,
) {
    companion object {
        fun from(m: Map<*, *>): AutoTrip {
            val stops = (m["stops"] as? List<*>)
                ?.mapNotNull { (it as? Map<*, *>)?.let(AutoTripStop::from) }
                ?: emptyList()
            val declaredCount = (m["stopCount"] as? Number)?.toInt()
            return AutoTrip(
                id = (m["id"] as? Number)?.toInt() ?: -1,
                title = (m["title"] as? String).orEmpty(),
                originAddress = m["originAddress"] as? String,
                destinationAddress = m["destinationAddress"] as? String,
                totalDistanceKm = (m["totalDistanceKm"] as? Number)?.toDouble(),
                totalDriveMinutes = (m["totalDriveMinutes"] as? Number)?.toDouble(),
                totalChargingMinutes = (m["totalChargingMinutes"] as? Number)?.toDouble(),
                totalCost = (m["totalCost"] as? Number)?.toDouble(),
                currency = (m["currency"] as? String).orEmpty(),
                stopCount = declaredCount ?: stops.size,
                stops = stops,
            )
        }

        /** Parses the `trips` array out of a `getSavedTrips` result map. */
        fun listFrom(result: Map<String, Any?>): List<AutoTrip> {
            val list = result["trips"] as? List<*> ?: return emptyList()
            return list.mapNotNull { (it as? Map<*, *>)?.let(::from) }
        }

        /** Parses the `trip` object out of a `getSavedTripDetail` result map. */
        fun detailFrom(result: Map<String, Any?>): AutoTrip? {
            val m = result["trip"] as? Map<*, *> ?: return null
            return from(m)
        }
    }
}

/** A single charging stop on a saved trip (display-only). */
data class AutoTripStop(
    val sequence: Int,
    val locationName: String,
    val locationAddress: String?,
    val lat: Double?,
    val lng: Double?,
    val connectorType: String,
    val powerKw: Double?,
    val arrivalSoc: Double?,
    val departureSoc: Double?,
    val chargingMinutes: Double?,
    val cost: Double?,
) {
    companion object {
        fun from(m: Map<*, *>): AutoTripStop = AutoTripStop(
            sequence = (m["sequence"] as? Number)?.toInt() ?: 0,
            locationName = (m["locationName"] as? String).orEmpty(),
            locationAddress = m["locationAddress"] as? String,
            lat = (m["lat"] as? Number)?.toDouble(),
            lng = (m["lng"] as? Number)?.toDouble(),
            connectorType = (m["connectorType"] as? String).orEmpty(),
            powerKw = (m["powerKw"] as? Number)?.toDouble(),
            arrivalSoc = (m["arrivalSoc"] as? Number)?.toDouble(),
            departureSoc = (m["departureSoc"] as? Number)?.toDouble(),
            chargingMinutes = (m["chargingMinutes"] as? Number)?.toDouble(),
            cost = (m["cost"] as? Number)?.toDouble(),
        )
    }
}

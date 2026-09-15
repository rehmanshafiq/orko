package com.orko_hubco.mobile.orko_hubco.auto.model

/**
 * Sanitized, display-only station detail from the Dart bridge
 * (`getStationDetail`). Public station info only — no user PII.
 */
data class AutoStationDetail(
    val id: String,
    val name: String,
    val address: String,
    val open: Boolean,
    val openingTime: String,
    val closingTime: String,
    val distanceKm: Double?,
    val connectors: List<AutoConnector>,
    val averageRating: Double?,
    val contactNumber: String,
    val lat: Double?,
    val lng: Double?,
) {
    /** Human hours label, e.g. "09:00 - 21:00", or empty when unknown. */
    val hoursLabel: String
        get() = if (openingTime.isNotBlank() && closingTime.isNotBlank()) {
            "$openingTime - $closingTime"
        } else {
            ""
        }

    companion object {
        fun from(result: Map<String, Any?>): AutoStationDetail? {
            val m = result["station"] as? Map<*, *> ?: return null
            val connectors = (m["connectors"] as? List<*>)
                ?.mapNotNull { (it as? Map<*, *>)?.let(AutoConnector::from) }
                ?: emptyList()
            return AutoStationDetail(
                id = m["id"]?.toString().orEmpty(),
                name = (m["name"] as? String).orEmpty(),
                address = (m["address"] as? String).orEmpty(),
                open = m["open"] as? Boolean ?: false,
                openingTime = (m["openingTime"] as? String).orEmpty(),
                closingTime = (m["closingTime"] as? String).orEmpty(),
                distanceKm = (m["distanceKm"] as? Number)?.toDouble(),
                connectors = connectors,
                averageRating = (m["averageRating"] as? Number)?.toDouble(),
                contactNumber = (m["contactNumber"] as? String).orEmpty(),
                lat = (m["lat"] as? Number)?.toDouble(),
                lng = (m["lng"] as? Number)?.toDouble(),
            )
        }
    }
}

/** A single connector on a station (display-only). */
data class AutoConnector(
    val type: String,
    val powerKw: String,
    val priceLabel: String,
    val state: String,
) {
    /** e.g. "DC 60 kW" (falls back gracefully when fields are missing). */
    val header: String
        get() {
            val parts = mutableListOf<String>()
            if (type.isNotBlank()) parts.add(type)
            if (powerKw.isNotBlank()) parts.add("$powerKw kW")
            return parts.joinToString(" ").ifEmpty { "Connector" }
        }

    companion object {
        fun from(m: Map<*, *>): AutoConnector = AutoConnector(
            type = (m["type"] as? String).orEmpty(),
            powerKw = m["powerKw"]?.toString().orEmpty(),
            priceLabel = (m["priceLabel"] as? String).orEmpty(),
            state = (m["state"] as? String).orEmpty(),
        )
    }
}

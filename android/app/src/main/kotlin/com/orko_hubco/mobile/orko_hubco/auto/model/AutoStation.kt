package com.orko_hubco.mobile.orko_hubco.auto.model

/**
 * Sanitized, display-only station data received from the Dart bridge
 * (`getNearbyStations`). Public station info only — no user PII.
 */
data class AutoStation(
    val id: String,
    val name: String,
    val address: String,
    val distanceKm: Double?,
    val available: Boolean,
    val availableConnectors: Int?,
    val numberOfConnectors: Int?,
    val connectorTypes: List<String>,
    val powerKw: List<Double>,
    val priceLabel: String,
    val lat: Double?,
    val lng: Double?,
) {
    companion object {
        fun from(m: Map<*, *>): AutoStation = AutoStation(
            id = m["id"]?.toString().orEmpty(),
            name = (m["name"] as? String).orEmpty(),
            address = (m["address"] as? String).orEmpty(),
            distanceKm = (m["distanceKm"] as? Number)?.toDouble(),
            available = m["available"] as? Boolean ?: false,
            availableConnectors = (m["availableConnectors"] as? Number)?.toInt(),
            numberOfConnectors = (m["numberOfConnectors"] as? Number)?.toInt(),
            connectorTypes = (m["connectorTypes"] as? List<*>)
                ?.mapNotNull { it as? String } ?: emptyList(),
            powerKw = (m["powerKw"] as? List<*>)
                ?.mapNotNull { (it as? Number)?.toDouble() } ?: emptyList(),
            priceLabel = (m["priceLabel"] as? String).orEmpty(),
            lat = (m["lat"] as? Number)?.toDouble(),
            lng = (m["lng"] as? Number)?.toDouble(),
        )

        /** Parses the `stations` array out of a `getNearbyStations` result map. */
        fun listFrom(result: Map<String, Any?>): List<AutoStation> {
            val list = result["stations"] as? List<*> ?: return emptyList()
            return list.mapNotNull { (it as? Map<*, *>)?.let(::from) }
        }
    }
}

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
    /** Human hours label, e.g. "9:00 AM - 10:00 PM", "24 hours", or empty. */
    val hoursLabel: String
        get() {
            if (openingTime.isBlank() || closingTime.isBlank()) return ""
            if (isAllDay(openingTime, closingTime)) return "24 hours"
            return "${to12Hour(openingTime)} - ${to12Hour(closingTime)}"
        }

    /** Converts "HH:mm[:ss]" to a 12-hour clock label, e.g. "22:00:00" → "10:00 PM". */
    private fun to12Hour(raw: String): String {
        val parts = raw.trim().split(":")
        val h = parts.getOrNull(0)?.toIntOrNull() ?: return raw.trim()
        val m = parts.getOrNull(1)?.toIntOrNull() ?: 0
        val period = if (h < 12) "AM" else "PM"
        val hour12 = (h % 12).let { if (it == 0) 12 else it }
        return String.format("%d:%02d %s", hour12, m, period)
    }

    /** True when the open/close times span the whole day (e.g. 00:00–23:59). */
    private fun isAllDay(open: String, close: String): Boolean {
        val o = open.trim()
        val c = close.trim()
        val opensAtMidnight = o == "00:00" || o == "0:00" ||
            o.startsWith("00:00:00")
        val closesEndOfDay = c == "23:59" || c == "24:00" ||
            c.startsWith("23:59:59") || c.startsWith("24:00:00") ||
            c.startsWith("00:00:00") || c == "00:00"
        return opensAtMidnight && closesEndOfDay
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

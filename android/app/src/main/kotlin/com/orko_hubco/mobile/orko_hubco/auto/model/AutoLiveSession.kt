package com.orko_hubco.mobile.orko_hubco.auto.model

/**
 * Sanitized, display-only live charging telemetry from the Dart bridge
 * (`getLiveSession`). Telemetry only — no payment details or PII.
 */
data class AutoLiveSession(
    val locationName: String?,
    val percent: Double?,
    val speedKw: Double?,
    val energyKwh: Double?,
    val timeLeft: String?,
    val cost: Double?,
) {
    companion object {
        /** Parses the `session` object out of a `getLiveSession` result map. */
        fun from(result: Map<String, Any?>): AutoLiveSession? {
            val m = result["session"] as? Map<*, *> ?: return null
            return AutoLiveSession(
                locationName = m["locationName"] as? String,
                percent = (m["percent"] as? Number)?.toDouble(),
                speedKw = (m["speedKw"] as? Number)?.toDouble(),
                energyKwh = (m["energyKwh"] as? Number)?.toDouble(),
                timeLeft = m["timeLeft"] as? String,
                cost = (m["cost"] as? Number)?.toDouble(),
            )
        }
    }
}

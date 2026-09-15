package com.orko_hubco.mobile.orko_hubco.auto.util

import android.content.Intent
import android.net.Uri
import androidx.car.app.CarContext
import androidx.car.app.CarToast
import java.util.Locale

/**
 * Starts turn-by-turn navigation to a station by handing off to the car's
 * navigation app (Google Maps) via the standard [CarContext.ACTION_NAVIGATE]
 * geo intent. HUBCO uses the CHARGING category, so we do NOT draw our own map —
 * we delegate to the installed nav app.
 *
 * Only coordinates + a short public label are passed. No PII.
 */
object CarNavigation {

    /**
     * Launches navigation to [lat]/[lng]. Returns true if an app accepted the
     * intent, false (with a toast) otherwise. Never throws.
     *
     * Must be triggered by an explicit user tap — never auto-started.
     */
    fun navigateTo(
        carContext: CarContext,
        lat: Double,
        lng: Double,
        label: String,
    ): Boolean {
        return try {
            val intent = Intent(CarContext.ACTION_NAVIGATE, buildGeoUri(lat, lng, label))
            carContext.startCarApp(intent)
            true
        } catch (e: Exception) {
            CarToast.makeText(
                carContext,
                "No navigation app available",
                CarToast.LENGTH_LONG,
            ).show()
            false
        }
    }

    /**
     * Builds `geo:0,0?q=<lat>,<lng>(<label>)`. Coordinates are formatted with a
     * fixed locale (always `.` decimal separator); the label is URL-encoded so
     * no unescaped text can alter the query.
     */
    private fun buildGeoUri(lat: Double, lng: Double, label: String): Uri {
        val coords = String.format(Locale.US, "%.6f,%.6f", lat, lng)
        val safeLabel = label.trim()
        return if (safeLabel.isEmpty()) {
            Uri.parse("geo:0,0?q=$coords")
        } else {
            val encoded = Uri.encode(safeLabel)
            Uri.parse("geo:0,0?q=$coords($encoded)")
        }
    }
}

package com.orko_hubco.mobile.orko_hubco.auto.util

import android.Manifest
import android.annotation.SuppressLint
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.os.Build
import android.os.Bundle
import androidx.car.app.CarContext

/**
 * Permission-guarded, coarse wrapper over the platform [LocationManager] for the
 * car screens.
 *
 * The car app needs a location for two things the host cannot give it: the map
 * anchor on [androidx.car.app.model.PlaceListMapTemplate] and deciding when the
 * driver has moved far enough that the nearby-station markers are stale. Station
 * queries themselves still go through the Dart bridge, which resolves its own
 * position when none is supplied.
 *
 * Updates are deliberately slow and coarse (see [MIN_TIME_MS] / [MIN_DISTANCE_M]):
 * the car host throttles template updates, so a chatty listener would burn the
 * template refresh budget for no visible gain.
 */
class CarLocationSource(private val carContext: CarContext) {

    private var manager: LocationManager? = null
    private var listener: LocationListener? = null

    /** True when either location permission is granted to the phone app. */
    fun hasPermission(): Boolean =
        carContext.checkSelfPermission(Manifest.permission.ACCESS_FINE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED ||
            carContext.checkSelfPermission(Manifest.permission.ACCESS_COARSE_LOCATION) ==
            PackageManager.PERMISSION_GRANTED

    /** Best cached fix across the available providers, or null. */
    @SuppressLint("MissingPermission")
    fun lastKnown(): Location? {
        if (!hasPermission()) return null
        val lm = locationManager() ?: return null
        return providers(lm)
            .mapNotNull { runCatching { lm.getLastKnownLocation(it) }.getOrNull() }
            .maxByOrNull { it.time }
    }

    /**
     * Starts coarse updates on the main looper. No-op without permission or when
     * already started; safe to call from `onStart`.
     */
    @SuppressLint("MissingPermission")
    fun start(onLocation: (Location) -> Unit) {
        if (listener != null || !hasPermission()) return
        val lm = locationManager() ?: return
        val provider = providers(lm).firstOrNull { runCatching { lm.isProviderEnabled(it) }.getOrDefault(false) }
            ?: return

        // All four callbacks are implemented explicitly: the default methods on
        // LocationListener only exist from API 30, and this app ships to API 23.
        @Suppress("OVERRIDE_DEPRECATION")
        val l = object : LocationListener {
            override fun onLocationChanged(location: Location) = onLocation(location)
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) = Unit
            override fun onProviderEnabled(provider: String) = Unit
            override fun onProviderDisabled(provider: String) = Unit
        }
        val started = runCatching {
            lm.requestLocationUpdates(provider, MIN_TIME_MS, MIN_DISTANCE_M, l)
        }.isSuccess
        if (started) listener = l
    }

    /** Stops updates. Idempotent; safe to call from `onStop` and `onDestroy`. */
    fun stop() {
        val l = listener ?: return
        listener = null
        runCatching { manager?.removeUpdates(l) }
    }

    private fun locationManager(): LocationManager? {
        manager?.let { return it }
        val lm = carContext.getSystemService(LocationManager::class.java)
        manager = lm
        return lm
    }

    /** Fused first where it exists (API 31+), then network, then GPS. */
    private fun providers(lm: LocationManager): List<String> {
        val available = runCatching { lm.allProviders }.getOrDefault(emptyList())
        val preferred = buildList {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) add(LocationManager.FUSED_PROVIDER)
            add(LocationManager.NETWORK_PROVIDER)
            add(LocationManager.GPS_PROVIDER)
        }
        return preferred.filter { it in available }
    }

    companion object {
        private const val MIN_TIME_MS = 30_000L
        private const val MIN_DISTANCE_M = 250f
    }
}

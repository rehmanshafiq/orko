package com.orko_hubco.mobile.orko_hubco.auto

import android.content.pm.ApplicationInfo
import androidx.car.app.CarAppService
import androidx.car.app.Session
import androidx.car.app.validation.HostValidator

/**
 * Android Auto entry point for HUBCO Green.
 *
 * Declared in the manifest with the `androidx.car.app.category.POI` category
 * (Google deprecated the explicit CHARGING/PARKING categories; EV-charging apps
 * now use the broader POI category) so the car experience is discoverable by the
 * Android Auto host.
 * This service hosts native Car App templates only — no Flutter UI is rendered in
 * the car. Data is fed from the app's real Dart stack via a cached FlutterEngine
 * bridge.
 *
 * LIFECYCLE: this service is long-lived (bound by the host), but it owns no
 * engine itself. The cached FlutterEngine is created and destroyed per
 * connection by [OrkoSession] (one Session per car connection), so a
 * connect/disconnect cycle fully releases the engine and never leaks it across
 * sessions or into the phone app's own engine.
 */
class OrkoCarAppService : CarAppService() {

    /**
     * Validates which hosts may bind this service.
     *
     * Debug builds allow any host so the Desktop Head Unit (DHU) and local tools
     * can connect. Release builds restrict binding to the hosts on the Car App
     * Library's maintained allowlist ([HostValidator] `hosts_allowlist_sample`),
     * which covers the signed Android Auto / Android Automotive hosts. Using the
     * library-provided array (rather than a hand-maintained copy) keeps the
     * allowlist correct across library updates and avoids both stale lock-outs
     * and accidental over-permissioning.
     */
    override fun createHostValidator(): HostValidator {
        val debuggable =
            (applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE) != 0
        return if (debuggable) {
            HostValidator.ALLOW_ALL_HOSTS_VALIDATOR
        } else {
            HostValidator.Builder(applicationContext)
                .addAllowedHosts(androidx.car.app.R.array.hosts_allowlist_sample)
                .build()
        }
    }

    override fun onCreateSession(): Session = OrkoSession()
}

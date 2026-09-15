package com.orko_hubco.mobile.orko_hubco.auto.screens

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.CarColor
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.orko_hubco.mobile.orko_hubco.auto.bridge.FlutterAutoBridge
import com.orko_hubco.mobile.orko_hubco.auto.model.AutoTrip
import com.orko_hubco.mobile.orko_hubco.auto.model.AutoTripStop
import com.orko_hubco.mobile.orko_hubco.auto.util.CarNavigation
import com.orko_hubco.mobile.orko_hubco.auto.util.ErrorScreens
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.util.Locale

/**
 * Read-only saved-trip detail in a [PaneTemplate]: a summary row plus one row
 * per charging stop, backed by live data via [FlutterAutoBridge].
 *
 * "Navigate to next stop" hands off to the car's nav app (single destination —
 * the car geo intent has no waypoints; multi-stop journeys stay mobile-only).
 * No create / edit / delete controls.
 */
class TripDetailScreen(
    carContext: CarContext,
    private val bridge: FlutterAutoBridge,
    private val tripId: Int,
    private val titleHint: String,
) : Screen(carContext), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var loadJob: Job? = null

    private var loading = true
    private var errorCode: String? = null
    private var trip: AutoTrip? = null

    init {
        lifecycle.addObserver(this)
    }

    override fun onStart(owner: LifecycleOwner) {
        load()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        scope.cancel()
    }

    private fun load() {
        loadJob?.cancel()
        loading = true
        errorCode = null
        invalidate()
        loadJob = scope.launch {
            val result = bridge.getSavedTripDetail(tripId)
            if (result["ok"] == true) {
                trip = AutoTrip.detailFrom(result)
                errorCode = if (trip == null) "server" else null
            } else {
                val code = result["error"] as? String ?: "server"
                if (code == "auth") {
                    loading = false
                    screenManager.push(SignInRequiredScreen(carContext, bridge))
                    return@launch
                }
                errorCode = code
            }
            loading = false
            invalidate()
        }
    }

    override fun onGetTemplate(): Template {
        val title = titleHint.ifEmpty { trip?.title ?: "Trip" }

        if (loading) {
            return PaneTemplate.Builder(Pane.Builder().setLoading(true).build())
                .setTitle(title)
                .setHeaderAction(Action.BACK)
                .build()
        }

        errorCode?.let {
            return ErrorScreens.forCode(carContext, it, title, Action.BACK) { load() }
        }

        val t = trip
            ?: return ErrorScreens.forCode(carContext, "server", title, Action.BACK) { load() }

        if (t.stops.isEmpty()) {
            return ErrorScreens.message(
                carContext,
                title = title,
                message = "This trip has no stops",
                headerAction = Action.BACK,
                onAction = null,
            )
        }

        val pane = Pane.Builder()
        val rows = mutableListOf<Row>()

        // Summary row first.
        rows.add(Row.Builder().setTitle("Summary").addText(summary(t)).build())

        // One row per charging stop.
        t.stops.forEach { stop ->
            rows.add(
                Row.Builder()
                    .setTitle("${stop.sequence}. ${stop.locationName.ifEmpty { "Stop" }}")
                    .addText(stopLine(stop))
                    .build()
            )
        }

        // Cap to the host's pane row limit so we never exceed it (would throw).
        rows.take(paneRowLimit()).forEach { pane.addRow(it) }

        // Navigate to the first stop (car geo intent = single destination).
        val firstStop = t.stops.first()
        pane.addAction(
            Action.Builder()
                .setTitle("Navigate to next stop")
                .setBackgroundColor(CarColor.PRIMARY)
                .setOnClickListener { navigateToStop(firstStop) }
                .build()
        )

        return PaneTemplate.Builder(pane.build())
            .setTitle(title)
            .setHeaderAction(Action.BACK)
            .build()
    }

    private fun navigateToStop(stop: AutoTripStop) {
        CarNavigation.navigateTo(
            carContext,
            stop.lat ?: 0.0,
            stop.lng ?: 0.0,
            stop.locationName,
        )
    }

    private fun summary(t: AutoTrip): CharSequence {
        val parts = mutableListOf<String>()
        t.totalDistanceKm?.let { parts.add("${trimNum(it)} km") }
        t.totalDriveMinutes?.let { parts.add("${trimNum(it)} min drive") }
        t.totalChargingMinutes?.let { parts.add("${trimNum(it)} min charging") }
        t.totalCost?.let { parts.add("${trimNum(it)} ${t.currency}".trim()) }
        return parts.joinToString(" · ").ifEmpty { "${t.stopCount} stops" }
    }

    private fun stopLine(stop: AutoTripStop): CharSequence {
        val parts = mutableListOf<String>()
        if (stop.arrivalSoc != null && stop.departureSoc != null) {
            parts.add("SoC ${trimNum(stop.arrivalSoc)}%→${trimNum(stop.departureSoc)}%")
        }
        stop.chargingMinutes?.let { parts.add("${trimNum(it)} min") }
        val connector = buildString {
            if (stop.connectorType.isNotBlank()) append(stop.connectorType)
            stop.powerKw?.let {
                if (isNotEmpty()) append(" ")
                append("${trimNum(it)} kW")
            }
        }
        if (connector.isNotBlank()) parts.add(connector)
        return parts.joinToString(" · ").ifEmpty { "—" }
    }

    private fun paneRowLimit(): Int = try {
        carContext.getCarService(ConstraintManager::class.java)
            .getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_PANE)
    } catch (e: Exception) {
        DEFAULT_PANE_LIMIT
    }

    private fun trimNum(d: Double): String =
        if (d == d.toLong().toDouble()) d.toLong().toString()
        else String.format(Locale.US, "%.1f", d)

    companion object {
        private const val DEFAULT_PANE_LIMIT = 4
    }
}

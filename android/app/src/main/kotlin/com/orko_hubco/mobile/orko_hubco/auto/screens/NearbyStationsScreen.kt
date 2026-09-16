package com.orko_hubco.mobile.orko_hubco.auto.screens

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.orko_hubco.mobile.orko_hubco.auto.bridge.FlutterAutoBridge
import com.orko_hubco.mobile.orko_hubco.auto.model.AutoStation
import com.orko_hubco.mobile.orko_hubco.auto.util.ErrorScreens
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Root authenticated screen: a driver-safe list of nearby charging stations,
 * ordered by distance, backed by live data via [FlutterAutoBridge].
 *
 * Reloads whenever the screen becomes visible (so returning from a pushed screen
 * re-queries). All data comes through the bridge — no direct backend access.
 */
class NearbyStationsScreen(
    carContext: CarContext,
    private val bridge: FlutterAutoBridge,
) : Screen(carContext), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var loadJob: Job? = null

    private var loading = true
    private var errorCode: String? = null
    private var stations: List<AutoStation> = emptyList()

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
            val result = bridge.getNearbyStations()
            val ok = result["ok"] == true
            if (ok) {
                stations = AutoStation.listFrom(result)
                errorCode = null
            } else {
                val code = result["error"] as? String ?: "server"
                if (code == "auth") {
                    // Signed out: route to the sign-in prompt instead of a list.
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
        if (loading) {
            return ListTemplate.Builder()
                .setLoading(true)
                .setTitle(TITLE)
                .setHeaderAction(Action.APP_ICON)
                .build()
        }

        errorCode?.let {
            return ErrorScreens.forCode(carContext, it, TITLE, Action.APP_ICON) { load() }
        }

        if (stations.isEmpty()) {
            return ErrorScreens.message(
                carContext,
                title = TITLE,
                message = "No stations nearby",
                headerAction = Action.APP_ICON,
                onAction = { load() },
            )
        }

        val list = ItemList.Builder()

        // Entry points to the other flows live as rows (a ListTemplate action
        // strip allows only one custom-title action, which is Refresh).
        list.addItem(
            Row.Builder()
                .setTitle("Active charging")
                .addText("Live charging status")
                .setBrowsable(true)
                .setOnClickListener {
                    screenManager.push(ChargingStatusScreen(carContext, bridge))
                }
                .build()
        )
        list.addItem(
            Row.Builder()
                .setTitle("My trips")
                .addText("Saved trips")
                .setBrowsable(true)
                .setOnClickListener {
                    screenManager.push(SavedTripsScreen(carContext, bridge))
                }
                .build()
        )

        // Reserve the two rows above; fill the rest with nearest stations.
        val stationCap = (rowLimit() - 2).coerceAtLeast(1)
        stations.take(stationCap).forEach { st ->
            list.addItem(
                Row.Builder()
                    .setTitle(st.name.ifEmpty { "Charging station" })
                    .addText(subtitle(st))
                    .setBrowsable(true)
                    .setOnClickListener { openDetail(st) }
                    .build()
            )
        }

        return ListTemplate.Builder()
            .setSingleList(list.build())
            .setTitle(TITLE)
            .setHeaderAction(Action.APP_ICON)
            .setActionStrip(actionStrip())
            .build()
    }

    private fun rowLimit(): Int = try {
        carContext.getCarService(ConstraintManager::class.java)
            .getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_LIST)
    } catch (e: Exception) {
        MAX_ROWS
    }

    private fun subtitle(st: AutoStation): CharSequence {
        val parts = mutableListOf<String>()
        st.distanceKm?.let { parts.add(String.format("%.1f km", it)) }
        if (st.numberOfConnectors != null) {
            parts.add("${st.availableConnectors ?: 0}/${st.numberOfConnectors}")
        }
        if (st.connectorTypes.isNotEmpty()) {
            parts.add(st.connectorTypes.joinToString("/"))
        }
        return parts.joinToString(" · ").ifEmpty { st.address }
    }

    private fun actionStrip(): ActionStrip {
        // A ListTemplate action strip permits at most one custom-title action.
        val refresh = Action.Builder()
            .setTitle("Refresh")
            .setOnClickListener { load() }
            .build()
        return ActionStrip.Builder()
            .addAction(refresh)
            .build()
    }

    private fun openDetail(st: AutoStation) {
        screenManager.push(
            StationDetailScreen(
                carContext,
                bridge,
                st.id,
                st.lat ?: 0.0,
                st.lng ?: 0.0,
                st.name,
            )
        )
    }

    companion object {
        private const val TITLE = "Nearby stations"
        // Head units cap list items; show the nearest handful, no heavy paging.
        private const val MAX_ROWS = 6
    }
}

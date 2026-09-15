package com.orko_hubco.mobile.orko_hubco.auto.screens

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.ItemList
import androidx.car.app.model.ListTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.orko_hubco.mobile.orko_hubco.auto.bridge.FlutterAutoBridge
import com.orko_hubco.mobile.orko_hubco.auto.model.AutoTrip
import com.orko_hubco.mobile.orko_hubco.auto.util.ErrorScreens
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import java.util.Locale

/**
 * Read-only list of the user's saved trips, backed by live data via
 * [FlutterAutoBridge]. Tapping a trip opens [TripDetailScreen]. No create /
 * edit / delete — planning stays on the phone.
 */
class SavedTripsScreen(
    carContext: CarContext,
    private val bridge: FlutterAutoBridge,
) : Screen(carContext), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var loadJob: Job? = null

    private var loading = true
    private var errorCode: String? = null
    private var trips: List<AutoTrip> = emptyList()

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
            val result = bridge.getSavedTrips()
            if (result["ok"] == true) {
                trips = AutoTrip.listFrom(result)
                errorCode = null
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
        if (loading) {
            return ListTemplate.Builder()
                .setLoading(true)
                .setTitle(TITLE)
                .setHeaderAction(Action.BACK)
                .build()
        }

        errorCode?.let {
            return ErrorScreens.forCode(carContext, it, TITLE, Action.BACK) { load() }
        }

        if (trips.isEmpty()) {
            return ErrorScreens.message(
                carContext,
                title = TITLE,
                message = "No saved trips",
                headerAction = Action.BACK,
                onAction = { load() },
            )
        }

        val list = ItemList.Builder()
        trips.take(rowLimit()).forEach { trip ->
            list.addItem(
                Row.Builder()
                    .setTitle(trip.title.ifEmpty { "Trip #${trip.id}" })
                    .addText(subtitle(trip))
                    .setBrowsable(true)
                    .setOnClickListener { openDetail(trip) }
                    .build()
            )
        }

        return ListTemplate.Builder()
            .setSingleList(list.build())
            .setTitle(TITLE)
            .setHeaderAction(Action.BACK)
            .build()
    }

    private fun subtitle(trip: AutoTrip): CharSequence {
        val parts = mutableListOf<String>()
        trip.totalDistanceKm?.let { parts.add("${trimNum(it)} km") }
        parts.add("${trip.stopCount} stops")
        trip.totalCost?.let { parts.add("${trimNum(it)} ${trip.currency}".trim()) }
        return parts.joinToString(" · ")
    }

    private fun openDetail(trip: AutoTrip) {
        screenManager.push(TripDetailScreen(carContext, bridge, trip.id, trip.title))
    }

    private fun rowLimit(): Int = try {
        carContext.getCarService(ConstraintManager::class.java)
            .getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_LIST)
    } catch (e: Exception) {
        DEFAULT_ROW_LIMIT
    }

    private fun trimNum(d: Double): String =
        if (d == d.toLong().toDouble()) d.toLong().toString()
        else String.format(Locale.US, "%.1f", d)

    companion object {
        private const val TITLE = "My trips"
        private const val DEFAULT_ROW_LIMIT = 6
    }
}

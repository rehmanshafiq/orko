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
import com.orko_hubco.mobile.orko_hubco.auto.model.AutoStationDetail
import com.orko_hubco.mobile.orko_hubco.auto.util.CarNavigation
import com.orko_hubco.mobile.orko_hubco.auto.util.ErrorScreens
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Station details in a driver-safe [PaneTemplate], backed by live data via
 * [FlutterAutoBridge]. Shows address, open/closed + hours, connectors and price,
 * plus a Navigate action (wired to a maps intent in Phase 6).
 */
class StationDetailScreen(
    carContext: CarContext,
    private val bridge: FlutterAutoBridge,
    private val stationId: String,
    private val lat: Double,
    private val lng: Double,
    private val name: String,
) : Screen(carContext), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var loadJob: Job? = null

    private var loading = true
    private var errorCode: String? = null
    private var detail: AutoStationDetail? = null

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
            val result = bridge.getStationDetail(stationId, lat, lng)
            if (result["ok"] == true) {
                detail = AutoStationDetail.from(result)
                errorCode = if (detail == null) "server" else null
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
        val title = name.ifEmpty { detail?.name ?: "Station" }

        if (loading) {
            // Navigate is offered before the detail fetch finishes: the row that
            // pushed this screen already supplied the coordinates, so a driver
            // who only wants directions never waits on the network. A Pane's
            // "empty while loading" rule counts rows only, so the action is legal.
            val pane = Pane.Builder().setLoading(true)
            navigateAction()?.let { pane.addAction(it) }
            return PaneTemplate.Builder(pane.build())
                .setTitle(title)
                .setHeaderAction(Action.BACK)
                .build()
        }

        errorCode?.let {
            return ErrorScreens.forCode(carContext, it, title, Action.BACK) { load() }
        }

        val d = detail
            ?: return ErrorScreens.forCode(carContext, "server", title, Action.BACK) { load() }

        val pane = Pane.Builder()

        // Build candidate rows in priority order, then cap to the pane row limit
        // (strict head units allow only a handful of rows on a PaneTemplate).
        val rows = mutableListOf<Row>()

        val statusText = buildString {
            append(if (d.open) "Open" else "Closed")
            if (d.hoursLabel.isNotEmpty()) append(" · ${d.hoursLabel}")
        }
        rows.add(Row.Builder().setTitle("Status").addText(statusText).build())

        if (d.address.isNotBlank()) {
            rows.add(Row.Builder().setTitle("Address").addText(d.address).build())
        }

        // Pricing as its own section (uniform across connectors).
        val price = d.connectors.firstNotNullOfOrNull { it.priceDisplay.ifBlank { null } }
        if (price != null) {
            rows.add(Row.Builder().setTitle("Pricing").addText(price).build())
        }

        if (d.contactNumbers.isNotEmpty()) {
            val contactRow = Row.Builder().setTitle("Contact No.")
            // Each number on its own line (row text lines are capped by the host).
            d.contactNumbers.take(MAX_ROW_TEXT_LINES).forEach { contactRow.addText(it) }
            rows.add(contactRow.build())
        }

        if (d.connectors.isNotEmpty()) {
            // Section heading for the charger list; each port shows only its state.
            rows.add(Row.Builder().setTitle("Charger Ports").build())
            d.connectors.forEach { c ->
                rows.add(
                    Row.Builder()
                        .setTitle(c.header)
                        .addText(c.stateDisplay.ifBlank { "—" })
                        .build()
                )
            }
        }

        d.averageRating?.takeIf { it > 0 }?.let { rating ->
            rows.add(
                Row.Builder()
                    .setTitle("Rating")
                    .addText(String.format("%.1f", rating))
                    .build()
            )
        }

        rows.take(paneRowLimit()).forEach { pane.addRow(it) }

        navigateAction()?.let { pane.addAction(it) }

        return PaneTemplate.Builder(pane.build())
            .setTitle(title)
            .setHeaderAction(Action.BACK)
            .build()
    }

    private fun paneRowLimit(): Int = try {
        carContext.getCarService(ConstraintManager::class.java)
            .getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_PANE)
    } catch (e: Exception) {
        MAX_PANE_ROWS
    }

    /**
     * The Navigate action, or null when we have no usable coordinates yet —
     * handing a geo intent 0,0 would send the driver to the Atlantic.
     */
    private fun navigateAction(): Action? {
        val d = detail
        // Prefer the detail's own coordinates; fall back to the ones passed in.
        val navLat = d?.lat ?: lat
        val navLng = d?.lng ?: lng
        if (navLat == 0.0 && navLng == 0.0) return null
        val label = name.ifEmpty { d?.name.orEmpty() }
        return Action.Builder()
            .setTitle("Navigate")
            .setBackgroundColor(CarColor.PRIMARY)
            .setOnClickListener {
                CarNavigation.navigateTo(carContext, navLat, navLng, label)
            }
            .build()
    }

    companion object {
        // Fallback pane row cap if the host's ConstraintManager is unavailable.
        private const val MAX_PANE_ROWS = 4
        // Row text lines a template row allows (host renders up to 2).
        private const val MAX_ROW_TEXT_LINES = 2
    }
}

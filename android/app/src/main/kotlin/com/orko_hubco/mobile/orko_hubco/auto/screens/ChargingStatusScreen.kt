package com.orko_hubco.mobile.orko_hubco.auto.screens

import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.Pane
import androidx.car.app.model.PaneTemplate
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.orko_hubco.mobile.orko_hubco.auto.bridge.FlutterAutoBridge
import com.orko_hubco.mobile.orko_hubco.auto.model.AutoLiveSession
import com.orko_hubco.mobile.orko_hubco.auto.util.ErrorScreens
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import java.util.Locale

/**
 * Read-only live charging telemetry in a [PaneTemplate], refreshed on a modest
 * timer ONLY while the screen is visible (started on Lifecycle.START, cancelled
 * on STOP) to conserve battery/data. Data comes through [FlutterAutoBridge].
 *
 * There is intentionally NO start/stop control — the backend exposes no
 * stop-charging endpoint and it would be unsafe while driving.
 */
class ChargingStatusScreen(
    carContext: CarContext,
    private val bridge: FlutterAutoBridge,
) : Screen(carContext), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private var pollJob: Job? = null

    private var firstLoad = true
    private var errorCode: String? = null
    private var active = false
    private var session: AutoLiveSession? = null

    init {
        lifecycle.addObserver(this)
    }

    override fun onStart(owner: LifecycleOwner) {
        startPolling()
    }

    override fun onStop(owner: LifecycleOwner) {
        stopPolling()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        scope.cancel()
    }

    private fun startPolling() {
        if (pollJob?.isActive == true) return
        pollJob = scope.launch {
            while (isActive) {
                tick()
                delay(POLL_INTERVAL_MS)
            }
        }
    }

    private fun stopPolling() {
        pollJob?.cancel()
        pollJob = null
    }

    private suspend fun tick() {
        val result = bridge.getLiveSession()
        if (result["ok"] == true) {
            active = result["active"] == true
            session = if (active) AutoLiveSession.from(result) else null
            errorCode = null
        } else {
            val code = result["error"] as? String ?: "server"
            if (code == "auth") {
                stopPolling()
                firstLoad = false
                screenManager.push(SignInRequiredScreen(carContext, bridge))
                return
            }
            errorCode = code
        }
        firstLoad = false
        invalidate()
    }

    override fun onGetTemplate(): Template {
        if (firstLoad) {
            return PaneTemplate.Builder(Pane.Builder().setLoading(true).build())
                .setTitle(TITLE)
                .setHeaderAction(Action.BACK)
                .build()
        }

        errorCode?.let { return errorTemplate(it) }

        if (!active) {
            return ErrorScreens.message(
                carContext,
                title = TITLE,
                message = "No active charging session",
                headerAction = Action.BACK,
                onAction = null,
            )
        }

        val s = session ?: return errorTemplate("server")
        val pane = Pane.Builder()
        val rows = mutableListOf<Row>()

        percentLabel(s.percent)?.let {
            rows.add(Row.Builder().setTitle("Charge").addText(it).build())
        }
        powerLabel(s)?.let {
            rows.add(Row.Builder().setTitle("Power").addText(it).build())
        }
        s.timeLeft?.takeIf { it.isNotBlank() }?.let {
            rows.add(Row.Builder().setTitle("Time left").addText(it).build())
        }
        costLabel(s.cost)?.let {
            rows.add(Row.Builder().setTitle("Cost").addText(it).build())
        }

        if (rows.isEmpty()) {
            rows.add(Row.Builder().setTitle("Charging").addText("In progress").build())
        }
        rows.take(MAX_PANE_ROWS).forEach { pane.addRow(it) }

        return PaneTemplate.Builder(pane.build())
            .setTitle(s.locationName?.takeIf { it.isNotBlank() } ?: TITLE)
            .setHeaderAction(Action.BACK)
            .build()
    }

    private fun percentLabel(percent: Double?): String? =
        percent?.let { "${trimNum(it)}%" }

    private fun powerLabel(s: AutoLiveSession): String? {
        val parts = mutableListOf<String>()
        s.speedKw?.let { parts.add("${trimNum(it)} kW") }
        s.energyKwh?.let { parts.add("${trimNum(it)} kWh") }
        return parts.joinToString(" · ").ifEmpty { null }
    }

    private fun costLabel(cost: Double?): String? = cost?.let { trimNum(it) }

    private fun trimNum(d: Double): String =
        if (d == d.toLong().toDouble()) {
            d.toLong().toString()
        } else {
            String.format(Locale.US, "%.1f", d)
        }

    private fun errorTemplate(code: String): Template =
        ErrorScreens.forCode(carContext, code, TITLE, Action.BACK) {
            firstLoad = true
            invalidate()
            startPolling()
        }

    companion object {
        private const val TITLE = "Active charging"
        private const val POLL_INTERVAL_MS = 15_000L
        private const val MAX_PANE_ROWS = 4
    }
}

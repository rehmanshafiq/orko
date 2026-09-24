package com.orko_hubco.mobile.orko_hubco.auto.screens

import android.location.Location
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.constraints.ConstraintManager
import androidx.car.app.model.Action
import androidx.car.app.model.ActionStrip
import androidx.car.app.model.CarColor
import androidx.car.app.model.CarIcon
import androidx.car.app.model.CarLocation
import androidx.car.app.model.Distance
import androidx.car.app.model.DistanceSpan
import androidx.car.app.model.ItemList
import androidx.car.app.model.Metadata
import androidx.car.app.model.Place
import androidx.car.app.model.PlaceListMapTemplate
import androidx.car.app.model.PlaceMarker
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.versioning.CarAppApiLevels
import androidx.core.graphics.drawable.IconCompat
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.orko_hubco.mobile.orko_hubco.R
import com.orko_hubco.mobile.orko_hubco.auto.bridge.FlutterAutoBridge
import com.orko_hubco.mobile.orko_hubco.auto.model.AutoStation
import com.orko_hubco.mobile.orko_hubco.auto.util.CarLocationSource
import com.orko_hubco.mobile.orko_hubco.auto.util.CarNavigation
import com.orko_hubco.mobile.orko_hubco.auto.util.ErrorScreens
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * Root authenticated screen: nearby charging stations as pins on the car's map
 * surface, backed by live data via [FlutterAutoBridge].
 *
 * MAP SURFACE: this is a [PlaceListMapTemplate]. The *host* draws the map and the
 * markers — a template app never touches the Maps SDK. Each station is one [Row]
 * carrying [Metadata] with a [Place]; the host drops a [PlaceMarker] for it.
 *
 * PINS ARE NOT TAP TARGETS. [Place], [PlaceMarker] and [Metadata] expose no
 * listener of any kind, and the host forwards no map input to a POI app, so a
 * marker cannot be clicked — it is a visual index into the list, nothing more.
 * The numeric marker labels exist for exactly that reason: pin "2" is row 2. The
 * row is the only tap target the library gives us.
 *
 * The navigation-category templates (NavigationTemplate, MapTemplate,
 * MapWithContentTemplate) are deliberately NOT used: they require the app to
 * render its own map onto a host-provided Surface and are restricted to apps in
 * the NAVIGATION category. This app is a POI app, so PlaceListMapTemplate is the
 * only way to get pins onto a host-drawn map.
 *
 * Reloads whenever the screen becomes visible (so returning from a pushed screen
 * re-queries), when the driver has moved far enough for the pins to be stale, and
 * on Refresh. All data comes through the bridge — no direct backend access.
 */
class NearbyStationsScreen(
    carContext: CarContext,
    private val bridge: FlutterAutoBridge,
) : Screen(carContext), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val locationSource = CarLocationSource(carContext)
    private var loadJob: Job? = null

    private var loading = true
    private var errorCode: String? = null
    private var stations: List<AutoStation> = emptyList()

    /** Last fix we have; anchors the map and drives the staleness check. */
    private var location: Location? = null

    /** Where the currently displayed markers were queried from. */
    private var queriedFrom: Location? = null

    init {
        lifecycle.addObserver(this)
    }

    override fun onStart(owner: LifecycleOwner) {
        location = locationSource.lastKnown() ?: location
        load()
        locationSource.start(::onLocationChanged)
    }

    override fun onStop(owner: LifecycleOwner) {
        locationSource.stop()
    }

    override fun onDestroy(owner: LifecycleOwner) {
        locationSource.stop()
        scope.cancel()
    }

    /**
     * Re-queries only once the driver has left the area the pins were fetched
     * for. Deliberately does not invalidate on every fix: the host caps how often
     * a screen may push templates, and a moving car would otherwise exhaust that
     * budget redrawing identical markers.
     */
    private fun onLocationChanged(fix: Location) {
        location = fix
        val from = queriedFrom
        if (from == null || from.distanceTo(fix) >= RELOAD_DISTANCE_M) load()
    }

    private fun load() {
        loadJob?.cancel()
        loading = true
        errorCode = null
        invalidate()
        val from = location
        loadJob = scope.launch {
            val result = bridge.getNearbyStations(from?.latitude, from?.longitude)
            val ok = result["ok"] == true
            if (ok) {
                // Defensive sort: markers are labelled 1..N by distance, so the
                // pin numbering has to match the row order the host shows.
                stations = AutoStation.listFrom(result)
                    .sortedBy { it.distanceKm ?: Double.MAX_VALUE }
                queriedFrom = from
                errorCode = null
            } else {
                val code = result["error"] as? String ?: "server"
                if (code == "auth") {
                    // Signed out: route to the sign-in prompt instead of a map.
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
            return mapTemplate().setLoading(true).build()
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
        // No clustering exists in the template model, and the host hard-caps how
        // many places it will draw, so the nearest N win and the rest are hidden.
        stations.take(markerLimit()).forEachIndexed { index, st ->
            list.addItem(stationRow(index, st))
        }

        return mapTemplate().setItemList(list.build()).build()
    }

    /** Shared base: everything that is identical across loading and loaded. */
    private fun mapTemplate(): PlaceListMapTemplate.Builder {
        val builder = PlaceListMapTemplate.Builder()
            // Title only, no header action: the template requires one or the
            // other, and the app icon just repeats the launcher badge the car
            // already shows in its status bar.
            .setTitle(TITLE)
            .setActionStrip(actionStrip())
            // The blue "you are here" dot is drawn by the host; it needs the
            // location permission the phone app already requests.
            .setCurrentLocationEnabled(locationSource.hasPermission())

        // Anchoring centres the map on the driver and is rendered distinctly
        // from the station pins.
        location?.let {
            builder.setAnchor(
                Place.Builder(CarLocation.create(it.latitude, it.longitude)).build()
            )
        }
        return builder
    }

    /**
     * One station as a row + its map pin. The [Metadata]'s [Place] is what turns
     * the row into a marker; the click listener belongs to the row alone, since
     * the host never reports marker taps back to the app.
     */
    private fun stationRow(index: Int, st: AutoStation): Row {
        val place = Place.Builder(
            CarLocation.create(st.lat ?: 0.0, st.lng ?: 0.0)
        ).setMarker(
            PlaceMarker.Builder()
                // Marker labels are capped at 3 characters by the library, so the
                // pin carries the rank and the row carries the name.
                .setLabel((index + 1).toString())
                .setColor(markerColor(st))
                .build()
        ).build()

        val rowAction = navigateAction(st)

        val row = Row.Builder()
            .setTitle(st.name.ifEmpty { "Charging station" })
            // Browsable draws the chevron, but Row.build() rejects a browsable
            // row that also carries an action ("A browsable row must not have a
            // secondary action set"). The two are mutually exclusive, so the
            // chevron yields to the directions button when that is in play.
            .setBrowsable(rowAction == null)
            .setMetadata(Metadata.Builder().setPlace(place).build())
            .setOnClickListener { openDetail(st) }

        // ROW_CONSTRAINTS_SIMPLE allows two text lines on this template: status
        // first, address second.
        row.addText(statusLine(st))
        if (st.address.isNotBlank()) row.addText(st.address)

        rowAction?.let { row.addAction(it) }
        return row.build()
    }

    /** Green when something is free to plug into, red when nothing is. */
    private fun markerColor(st: AutoStation): CarColor {
        val free = st.availableConnectors
        return when {
            free != null && free > 0 -> CarColor.GREEN
            free != null -> CarColor.RED
            st.available -> CarColor.GREEN
            else -> CarColor.DEFAULT
        }
    }

    /**
     * "3.1 km · 1/2 · DC". The distance is a [DistanceSpan] rather than a
     * formatted string so the host renders it in the driver's own unit system.
     */
    private fun statusLine(st: AutoStation): CharSequence {
        val parts = mutableListOf<String>()
        val km = st.distanceKm
        if (km != null) parts.add(DISTANCE_PLACEHOLDER)
        if (st.numberOfConnectors != null) {
            parts.add("${st.availableConnectors ?: 0}/${st.numberOfConnectors}")
        }
        if (st.connectorTypes.isNotEmpty()) {
            parts.add(st.connectorTypes.joinToString("/"))
        }
        if (parts.isEmpty()) return st.address

        val text = android.text.SpannableString(parts.joinToString(" · "))
        if (km != null) {
            text.setSpan(
                DistanceSpan.create(Distance.create(km, Distance.UNIT_KILOMETERS_P1)),
                0,
                DISTANCE_PLACEHOLDER.length,
                android.text.Spanned.SPAN_INCLUSIVE_EXCLUSIVE,
            )
        }
        return text
    }

    /**
     * The other flows live in the action strip now that the list is map-backed.
     * A map template's strip allows up to four actions with custom titles
     * (ACTIONS_CONSTRAINTS_NAVIGATION), unlike a ListTemplate's single one.
     */
    private fun actionStrip(): ActionStrip = ActionStrip.Builder()
        .addAction(
            Action.Builder()
                .setTitle("Charging")
                .setOnClickListener {
                    screenManager.push(ChargingStatusScreen(carContext, bridge))
                }
                .build()
        )
        .addAction(
            Action.Builder()
                .setTitle("Trips")
                .setOnClickListener {
                    screenManager.push(SavedTripsScreen(carContext, bridge))
                }
                .build()
        )
        .build()

    /**
     * EXPERIMENT (see [ROW_NAVIGATE_ACTION]): a one-tap directions button on the
     * row itself, or null when it is off, the host is too old, or the station has
     * no coordinates to navigate to. This template's rows declare
     * maxActionsExclusive = 0, which nothing validates — whether the host draws
     * the button is a matter of observed behaviour, not the API contract.
     */
    private fun navigateAction(st: AutoStation): Action? {
        if (!ROW_NAVIGATE_ACTION || carAppApiLevel() < CarAppApiLevels.LEVEL_6) return null
        val lat = st.lat ?: return null
        val lng = st.lng ?: return null
        if (lat == 0.0 && lng == 0.0) return null
        return Action.Builder()
            .setIcon(
                CarIcon.Builder(
                    IconCompat.createWithResource(carContext, R.drawable.ic_car_navigate)
                ).build()
            )
            .setOnClickListener { CarNavigation.navigateTo(carContext, lat, lng, st.name) }
            .build()
    }

    /** Host's Car API level, or the floor when the host has not reported one. */
    private fun carAppApiLevel(): Int = try {
        carContext.carAppApiLevel
    } catch (e: Exception) {
        CarAppApiLevels.LEVEL_1
    }

    /** How many pins the head unit will draw; strict units allow only a few. */
    private fun markerLimit(): Int = try {
        carContext.getCarService(ConstraintManager::class.java)
            .getContentLimit(ConstraintManager.CONTENT_LIMIT_TYPE_PLACE_LIST)
            .coerceAtLeast(1)
    } catch (e: Exception) {
        MAX_MARKERS
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
        // Fallback when the host does not report a place-list limit.
        private const val MAX_MARKERS = 6
        // Metres the driver must travel before the pins are re-queried.
        private const val RELOAD_DISTANCE_M = 500f
        // Stand-in text the host replaces with the localised distance.
        private const val DISTANCE_PLACEHOLDER = "  "
        // Per-row directions button. Unsupported on paper (list rows declare
        // zero actions in every library version through 1.7.0) but unvalidated,
        // so it is a host-behaviour question. Flip to false if a head unit
        // rejects or drops the template.
        private const val ROW_NAVIGATE_ACTION = true
    }
}

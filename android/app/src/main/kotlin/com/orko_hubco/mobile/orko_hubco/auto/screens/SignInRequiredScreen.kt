package com.orko_hubco.mobile.orko_hubco.auto.screens

import androidx.car.app.CarContext
import androidx.car.app.CarToast
import androidx.car.app.Screen
import androidx.car.app.model.Action
import androidx.car.app.model.Template
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import com.orko_hubco.mobile.orko_hubco.auto.bridge.FlutterAutoBridge
import com.orko_hubco.mobile.orko_hubco.auto.util.ErrorScreens
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch

/**
 * The auth gate. Shown whenever there is no signed-in session — either as the
 * root screen (signed out at launch) or pushed on top when a bridge call later
 * returns "auth" (session expired mid-use).
 *
 * The car NEVER collects credentials (unsafe while driving, and prohibited): the
 * user signs in on their phone, then taps Refresh. Refresh re-checks the session
 * via the bridge and, when signed in, advances to the station list (pushed on
 * top) or pops back to the screen that sent them here (mid-use expiry).
 *
 * No token, phone number, email, or user id is ever displayed.
 */
class SignInRequiredScreen(
    carContext: CarContext,
    private val bridge: FlutterAutoBridge,
) : Screen(carContext), DefaultLifecycleObserver {

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    init {
        lifecycle.addObserver(this)
    }

    override fun onDestroy(owner: LifecycleOwner) {
        scope.cancel()
    }

    override fun onGetTemplate(): Template = ErrorScreens.message(
        carContext = carContext,
        title = "Sign in required",
        message = "Open HUBCO Green on your phone to sign in.",
        headerAction = Action.APP_ICON,
        actionTitle = "Refresh",
        onAction = ::onRefresh,
    )

    private fun onRefresh() {
        scope.launch {
            if (bridge.isAuthenticated()) {
                // Signed in now: continue to the station list. Pop if we were
                // pushed on top; otherwise (we are the root) push the list.
                if (screenManager.stackSize > 1) {
                    screenManager.pop()
                } else {
                    screenManager.push(NearbyStationsScreen(carContext, bridge))
                }
            } else {
                CarToast.makeText(
                    carContext,
                    "Still signed out",
                    CarToast.LENGTH_SHORT,
                ).show()
            }
        }
    }
}

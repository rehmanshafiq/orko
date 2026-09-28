import CarPlay

/// The auth gate. Shown whenever there is no signed-in session — pushed on top
/// when a bridge call returns "auth" (signed out at launch, or a session
/// expiring mid-use). Counterpart of SignInRequiredScreen.kt.
///
/// The car NEVER collects credentials (unsafe while driving, and prohibited):
/// the user signs in on their phone, then taps Refresh. Refresh re-checks the
/// session via the bridge and, when signed in, pops back to the screen that sent
/// them here (which reloads on its onStart), or pushes the station list if this
/// is the root.
///
/// No token, phone number, email, or user id is ever displayed.
final class SignInRequiredScreen: CarScreen {

    init(bridge: FlutterAutoBridge) {
        let info = CPInformationTemplate(title: "Sign in required", layout: .leading, items: [], actions: [])
        super.init(bridge: bridge, template: info)
        ErrorScreens.apply(
            to: info,
            title: "Sign in required",
            message: "Open HUBCO Green on your phone to sign in.",
            actionTitle: "Refresh"
        ) { [weak self] in self?.onRefresh() }
    }

    private func onRefresh() {
        launch { [weak self] in
            guard let self else { return }
            let signedIn = await self.bridge.isAuthenticated()
            if Task.isCancelled { return }
            guard let manager = self.screenManager else { return }
            if signedIn {
                if manager.stackSize > 1 {
                    manager.pop()
                } else {
                    manager.push(NearbyStationsScreen(bridge: self.bridge))
                }
            } else {
                CarToast.show("Still signed out", on: manager)
            }
        }
    }
}

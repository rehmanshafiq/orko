import CarPlay
import Foundation

/// CarPlay counterpart of androidx.car.app `Screen`: one screen of the car UI,
/// represented by one CPTemplate, with the same lifecycle the Android screens
/// rely on.
///
///  - [onStart]   the screen became the visible top of the stack (Android
///                Lifecycle START) — load / start polling / start location here.
///  - [onStop]    it was covered, or the CarPlay scene went to the background.
///  - [onDestroy] it was popped off the stack or the car disconnected.
///
/// CarPlay templates are mutable objects, so a screen normally keeps ONE
/// template and updates it in place (the equivalent of Android's
/// `invalidate()`). A screen that must switch template type (the root: map vs
/// message) calls [replaceTemplate], which is only honoured while visible.
@MainActor
class CarScreen: NSObject {

    let bridge: FlutterAutoBridge

    /// Set by [CarScreenManager] when the screen is placed on the stack.
    weak var screenManager: CarScreenManager?

    /// The template currently representing this screen.
    private(set) var template: CPTemplate

    private(set) var isStarted = false
    private(set) var isDestroyed = false

    private var tasks: [UUID: Task<Void, Never>] = [:]

    init(bridge: FlutterAutoBridge, template: CPTemplate) {
        self.bridge = bridge
        self.template = template
        super.init()
    }

    // MARK: Lifecycle hooks (override in subclasses)

    func onStart() {}
    func onStop() {}
    func onDestroy() {}

    // MARK: Lifecycle dispatch (called by CarScreenManager only)

    final func dispatchStart() {
        guard !isStarted, !isDestroyed else { return }
        isStarted = true
        onStart()
    }

    final func dispatchStop() {
        guard isStarted else { return }
        isStarted = false
        onStop()
    }

    final func dispatchDestroy() {
        guard !isDestroyed else { return }
        dispatchStop()
        isDestroyed = true
        // Mirrors the Android screens cancelling their coroutine scope first,
        // so nothing touches the bridge during or after teardown.
        tasks.values.forEach { $0.cancel() }
        tasks.removeAll()
        onDestroy()
    }

    // MARK: Helpers for subclasses

    /// Runs async work tied to this screen's lifetime (Android: `scope.launch`).
    /// The task is cancelled on destroy; check `Task.isCancelled` after every
    /// `await` before touching the UI.
    @discardableResult
    final func launch(_ work: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        let id = UUID()
        let task = Task { @MainActor [weak self] in
            await work()
            self?.tasks[id] = nil
        }
        tasks[id] = task
        return task
    }

    /// Swaps the template that represents this screen (root screen only).
    final func replaceTemplate(_ newTemplate: CPTemplate) {
        guard newTemplate !== template, !isDestroyed else { return }
        let old = template
        template = newTemplate
        screenManager?.screen(self, didReplace: old)
    }
}

/// CarPlay counterpart of androidx.car.app `ScreenManager`: owns the stack of
/// [CarScreen]s on top of the CPInterfaceController and derives each screen's
/// start/stop/destroy from CarPlay's template callbacks.
@MainActor
final class CarScreenManager: NSObject, CPInterfaceControllerDelegate {

    let interfaceController: CPInterfaceController
    let scene: CPTemplateApplicationScene

    private var stack: [CarScreen] = []
    private var visibleScreen: CarScreen?
    private var sceneActive = true

    var stackSize: Int { stack.count }

    init(interfaceController: CPInterfaceController, scene: CPTemplateApplicationScene) {
        self.interfaceController = interfaceController
        self.scene = scene
        super.init()
        interfaceController.delegate = self
    }

    func setRoot(_ screen: CarScreen) {
        stack.forEach { $0.dispatchDestroy() }
        screen.screenManager = self
        stack = [screen]
        visibleScreen = nil
        interfaceController.setRootTemplate(screen.template, animated: false) { [weak self] _, _ in
            self?.reconcile()
        }
    }

    func push(_ screen: CarScreen) {
        screen.screenManager = self
        stack.append(screen)
        interfaceController.pushTemplate(screen.template, animated: true) { [weak self] _, error in
            guard let self else { return }
            if error != nil {
                // Rejected (e.g. template depth limit): undo so the stack stays true.
                self.stack.removeAll { $0 === screen }
                screen.dispatchDestroy()
            }
            self.reconcile()
        }
    }

    func pop() {
        guard stack.count > 1 else { return }
        interfaceController.popTemplate(animated: true) { [weak self] _, _ in
            self?.reconcile()
        }
    }

    /// The CarPlay scene moved to the background / foreground (the driver
    /// switched to another CarPlay app). Android delivers this as onStop/onStart.
    func setSceneActive(_ active: Bool) {
        sceneActive = active
        reconcile()
    }

    /// Tears down every screen (car disconnected).
    func destroyAll() {
        stack.reversed().forEach { $0.dispatchDestroy() }
        stack.removeAll()
        visibleScreen = nil
    }

    fileprivate func screen(_ screen: CarScreen, didReplace old: CPTemplate) {
        // Only the visible root may swap its template; a hidden screen keeps
        // its state and re-renders on its next onStart.
        guard stack.count == 1, stack.first === screen else { return }
        interfaceController.setRootTemplate(screen.template, animated: false) { [weak self] _, _ in
            self?.reconcile()
        }
    }

    // MARK: Lifecycle derivation

    /// Pops screens whose template CarPlay removed (Back tapped, or a
    /// programmatic pop), then starts the top screen and stops the previous
    /// one. Idempotent — safe to call from every callback.
    private func reconcile() {
        let live = interfaceController.templates
        while stack.count > 1, let top = stack.last,
              !live.contains(where: { $0 === top.template }) {
            stack.removeLast()
            top.dispatchDestroy()
        }

        let top = interfaceController.topTemplate
        let nowVisible = sceneActive ? stack.last(where: { $0.template === top }) : nil
        guard nowVisible !== visibleScreen else { return }
        visibleScreen?.dispatchStop()
        visibleScreen = nowVisible
        nowVisible?.dispatchStart()
    }

    nonisolated func templateDidAppear(_ aTemplate: CPTemplate, animated: Bool) {
        MainActor.assumeIsolatedCompat { self.reconcile() }
    }

    nonisolated func templateDidDisappear(_ aTemplate: CPTemplate, animated: Bool) {
        MainActor.assumeIsolatedCompat { self.reconcile() }
    }
}

extension MainActor {
    /// CarPlay delegate callbacks always arrive on the main thread; hop onto the
    /// main actor without an async gap where possible.
    static func assumeIsolatedCompat(_ body: @escaping @MainActor () -> Void) {
        if Thread.isMainThread {
            MainActor.assumeIsolated(body)
        } else {
            Task { @MainActor in body() }
        }
    }
}

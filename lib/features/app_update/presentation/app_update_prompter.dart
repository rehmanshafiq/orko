import 'package:flutter/material.dart';
import 'package:orko_hubco/core/router/app_router.dart';
import 'package:orko_hubco/core/services/app_update/app_update_service.dart';
import 'package:orko_hubco/core/utils/app_toast.dart';
import 'package:orko_hubco/features/app_update/presentation/widgets/soft_update_dialog.dart';

/// Shows the soft update prompt on the root navigator whenever
/// [AppUpdateService.softUpdatePending] is raised.
///
/// The force update screen needs nothing here: the router redirects to it.
///
/// A pending prompt is queued until it can be shown safely: the root navigator
/// exists, the splash screen has handed over (its navigation would tear the
/// dialog down) and no force update is active. Only one dialog is ever open,
/// and a force update removes it.
class AppUpdatePrompter {
  AppUpdatePrompter._();

  static bool _attached = false;
  static bool _retryScheduled = false;
  static DialogRoute<void>? _softRoute;

  /// Locations the soft prompt must not cover.
  static const Set<String> _blockedPaths = {'/splash', '/force-update'};

  /// Starts listening. Call once at app start-up, before `runApp`.
  static void attach() {
    if (_attached) return;
    _attached = true;
    final service = AppUpdateService.instance;
    service.softUpdatePending.addListener(_scheduleShow);
    service.forceUpdate.addListener(_onForceUpdateChanged);
    // Route changes (e.g. leaving splash) may unblock a queued prompt.
    AppRouter.router.routerDelegate.addListener(_scheduleShow);
  }

  static void _onForceUpdateChanged() {
    if (AppUpdateService.instance.forceUpdate.value) _dismissSoft();
  }

  /// Defers to after the current frame: notifications can arrive mid-build or
  /// mid-navigation, where pushing a route is not allowed.
  static void _scheduleShow() {
    if (_retryScheduled) return;
    _retryScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _retryScheduled = false;
      _showSoftIfReady();
    });
    WidgetsBinding.instance.ensureVisualUpdate();
  }

  static void _showSoftIfReady() {
    final service = AppUpdateService.instance;
    if (!service.softUpdatePending.value || service.forceUpdate.value) return;
    if (_softRoute?.isActive ?? false) return;

    final navigator = AppRouter.rootNavigatorKey.currentState;
    final path = _currentPath();
    // Not ready yet; the next route change retries.
    if (navigator == null || path == null || _blockedPaths.contains(path)) {
      return;
    }

    final route = DialogRoute<void>(
      context: navigator.context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (dialogContext) => SoftUpdateDialog(
        onUpdate: _onUpdatePressed,
        onLater: _dismissSoft,
      ),
    );
    _softRoute = route;
    service.markSoftUpdateShown();
    navigator.push(route).whenComplete(() {
      if (identical(_softRoute, route)) _softRoute = null;
    });
  }

  static Future<void> _onUpdatePressed() async {
    final service = AppUpdateService.instance;
    if (await service.openStore()) {
      _dismissSoft();
    } else {
      AppToast.error(
        'Couldn\'t open the ${service.storeName}. Please update the app '
        'from the ${service.storeName}.',
      );
    }
  }

  static void _dismissSoft() {
    final route = _softRoute;
    _softRoute = null;
    final navigator = route?.navigator;
    if (route == null || navigator == null || !route.isActive) return;
    // Animate out when on top; otherwise just drop it from the stack.
    if (route.isCurrent) {
      navigator.pop();
    } else {
      navigator.removeRoute(route);
    }
  }

  static String? _currentPath() {
    final config = AppRouter.router.routerDelegate.currentConfiguration;
    if (config.isEmpty) return null;
    return config.uri.path;
  }
}

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/utils/enums/app_enums.dart';

abstract class _BasicAppRoute {
  static replaceToNewScreen<T>({
    required BuildContext context,
    required String path,
    T? args,
    Map<String, dynamic>? queryParameters,
    Map<String, String>? pathParameters,
  }) {
    context.pushReplacementNamed(
      path,
      extra: args,
      queryParameters: queryParameters ?? {},
      pathParameters: pathParameters ?? {},
    );
  }
}

class AppNavigations {
  AppNavigations._();

  static String _routeNameFrom(AppRoute route) {
    switch (route) {
      case AppRoute.splash:
        return 'splash';
      case AppRoute.onboarding:
        return 'login';
      case AppRoute.bottomNavigation:
        return 'home';
    }
  }

  static void replace(BuildContext context, AppRoute route) {
    _BasicAppRoute.replaceToNewScreen(
      context: context,
      path: _routeNameFrom(route),
    );
  }

  static void navigateToOnBoarding(BuildContext context) {
    replace(context, AppRoute.onboarding);
  }

  static void navigateToBottomNavigation(BuildContext context) {
    replace(context, AppRoute.bottomNavigation);
  }
}

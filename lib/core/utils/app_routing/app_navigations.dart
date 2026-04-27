import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/utils/enums/app_enums.dart';

class AppNavigations {
  AppNavigations._();

  static void replace(BuildContext context, AppRoute route) {
    context.go(route.path);
  }
}

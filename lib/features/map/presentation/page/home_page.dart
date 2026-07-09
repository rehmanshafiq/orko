import 'package:flutter/material.dart';
import 'package:orko_hubco/core/utils/responsive_view_widget.dart';
import 'package:orko_hubco/features/map/presentation/view/home_mobile_view.dart';

/// Home (map) tab. The [MapCubit] is provided by the router branch that hosts
/// this page. See `app_router.dart`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveView(
      mobile: HomeMobileView(),
    );
  }
}

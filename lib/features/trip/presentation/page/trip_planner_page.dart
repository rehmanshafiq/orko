import 'package:flutter/material.dart';
import '../../../../core/utils/responsive_view_widget.dart';
import '../view/trip_planner_mobile_view.dart';

class TripPlannerPage extends StatelessWidget {
  const TripPlannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ResponsiveView(
      mobile: TripPlannerMobileView(),
    );
  }
}


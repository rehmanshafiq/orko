import 'package:flutter/material.dart';
import 'package:orko_hubco/core/utils/responsive_view_widget.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filters.dart';
import 'package:orko_hubco/features/map/presentation/view/filter_mobile_view.dart';

/// Filter results entry point. Shows the stations matching [filters] applied
/// from the map filters sheet, laid out as a vertical list. The [MapCubit] is
/// provided by the router branch that hosts this page (its own instance, so
/// filtering here never touches the home map). See `app_router.dart`.
class FilterPage extends StatelessWidget {
  const FilterPage({super.key, required this.filters});

  final StationFilters filters;

  @override
  Widget build(BuildContext context) {
    return ResponsiveView(
      mobile: FilterMobileView(filters: filters),
    );
  }
}

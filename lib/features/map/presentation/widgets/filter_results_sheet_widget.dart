import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';
import 'package:orko_hubco/features/map/presentation/widgets/filter_results_body_widget.dart';
import 'package:orko_hubco/features/map/presentation/widgets/station_filter_chips_widget.dart';

/// Results sheet (mirrors the home bottom sheet as a vertical list): a rounded
/// card with a drag handle, "Results" title, connector chips and the matching
/// stations. Reads the [MapCubit] itself; chip selection is owned by the view.
class FilterResultsSheetWidget extends StatelessWidget {
  const FilterResultsSheetWidget({
    super.key,
    required this.availableNowSelected,
    required this.selectedTypes,
    required this.onToggleAvailableNow,
    required this.onToggleType,
    required this.onRetry,
    required this.onStationTap,
  });

  final bool availableNowSelected;
  final Set<String> selectedTypes;
  final VoidCallback onToggleAvailableNow;
  final ValueChanged<String> onToggleType;
  final VoidCallback onRetry;
  final ValueChanged<HubcoLocationEntity> onStationTap;

  /// Distinct connector kinds (`type`) across [stations], sorted.
  List<String> _distinctConnectorTypes(List<HubcoLocationEntity> stations) {
    final set = <String>{};
    for (final s in stations) {
      set.addAll(s.connectorTypes);
    }
    return set.toList()..sort();
  }

  /// Applies the selected chips to [stations]: "Available Now" keeps only
  /// available stations; selected types keep stations matching any of them.
  List<HubcoLocationEntity> _applyChipFilters(
    List<HubcoLocationEntity> stations,
    Set<String> activeTypes,
  ) {
    return stations.where((s) {
      if (availableNowSelected && !s.available) return false;
      if (activeTypes.isNotEmpty &&
          !s.connectorTypes.any(activeTypes.contains)) {
        return false;
      }
      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      width: double.infinity,
      padding: AppUtils.homeBottomSheetPadding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: BlocBuilder<MapCubit, MapState>(
        builder: (context, state) {
          final locations = state is MapLoaded
              ? state.locations
              : const <HubcoLocationEntity>[];
          final types = _distinctConnectorTypes(locations);
          // Ignore stale selections for types not present in the current data.
          final activeTypes = selectedTypes.where(types.contains).toSet();
          final filtered = _applyChipFilters(locations, activeTypes);
          final hasActiveFilters =
              availableNowSelected || activeTypes.isNotEmpty;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                child: Container(
                  height: 3.h,
                  width: 66.w,
                  decoration: BoxDecoration(
                    color: ui.textSecondary.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
              12.verticalSpace,
              AppText(
                'Results',
                color: ui.textPrimary,
                fontSize: FontSizes.font24Sp,
                fontWeight: FontWeights.weight600,
              ),
              10.verticalSpace,
              StationFilterChipsWidget(
                types: types,
                availableNowSelected: availableNowSelected,
                selectedTypes: selectedTypes,
                onToggleAvailableNow: onToggleAvailableNow,
                onToggleType: onToggleType,
              ),
              12.verticalSpace,
              Expanded(
                child: FilterResultsBodyWidget(
                  state: state,
                  filtered: filtered,
                  hasActiveFilters: hasActiveFilters,
                  onRetry: onRetry,
                  onStationTap: onStationTap,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

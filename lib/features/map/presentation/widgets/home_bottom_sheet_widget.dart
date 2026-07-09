import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/widgets/home_filter_chips_widget.dart';
import 'package:orko_hubco/features/map/presentation/widgets/home_station_card_widget.dart';

/// Bottom sheet listing stations. When filters are applied it mirrors the
/// Filter results screen ("Results", full-width vertical cards once expanded);
/// otherwise it shows the distance-capped "Nearby Stations" list. The header
/// doubles as the drag target that expands/collapses the sheet.
class HomeBottomSheetWidget extends StatelessWidget {
  const HomeBottomSheetWidget({
    super.key,
    required this.expanded,
    required this.filtersApplied,
    required this.locations,
    required this.availableNowSelected,
    required this.selectedTypes,
    required this.onClearFilters,
    required this.onToggleAvailableNow,
    required this.onToggleType,
    required this.onHeaderDragEnd,
  });

  final bool expanded;
  final bool filtersApplied;
  final List<HubcoLocationEntity> locations;
  final bool availableNowSelected;
  final Set<String> selectedTypes;
  final VoidCallback onClearFilters;
  final VoidCallback onToggleAvailableNow;
  final ValueChanged<String> onToggleType;
  final ValueChanged<DragEndDetails> onHeaderDragEnd;

  /// Nearby Stations list only shows stations within this many km (based on the
  /// `distance` field from the charging-station map API). Display-only cap for
  /// the list; the map markers still show every station.
  static const double _nearbyStationsMaxDistanceKm = 30;

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
    final allStations = filtersApplied
        ? locations
        : locations
            .where((s) => s.distance <= _nearbyStationsMaxDistanceKm)
            .toList();
    final types = _distinctConnectorTypes(allStations);
    // Ignore any stale selections for types not present in the current data.
    final activeTypes = selectedTypes.where(types.contains).toSet();
    final nearbyStations = _applyChipFilters(allStations, activeTypes);
    final hasActiveFilters = availableNowSelected || activeTypes.isNotEmpty;

    return Container(
      padding: AppUtils.homeBottomSheetPadding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(22.r),
          topRight: Radius.circular(22.r),
        ),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
        children: [
          _header(context, ui, types),
          _listArea(context, ui, nearbyStations, hasActiveFilters),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, AppUiColors ui, List<String> types) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragEnd: onHeaderDragEnd,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          Row(
            children: [
              Expanded(
                child: AppText(
                  filtersApplied ? 'Results' : 'Nearby Stations',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font24Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ),
              // Only shown while filters are active; tapping resets the map.
              if (filtersApplied)
                GestureDetector(
                  onTap: onClearFilters,
                  behavior: HitTestBehavior.opaque,
                  child: AppText(
                    'Clear Filter',
                    color: AppColors.removeColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
            ],
          ),
          10.verticalSpace,
          HomeFilterChipsWidget(
            types: types,
            availableNowSelected: availableNowSelected,
            selectedTypes: selectedTypes,
            onToggleAvailableNow: onToggleAvailableNow,
            onToggleType: onToggleType,
          ),
          12.verticalSpace,
        ],
      ),
    );
  }

  Widget _listArea(
    BuildContext context,
    AppUiColors ui,
    List<HubcoLocationEntity> nearbyStations,
    bool hasActiveFilters,
  ) {
    if (nearbyStations.isEmpty) {
      final message = Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: AppText(
          hasActiveFilters
              ? 'No stations match the selected filters'
              : (filtersApplied
                  ? 'No stations match your filters'
                  : 'No stations available'),
          color: ui.textSecondary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight500,
        ),
      );
      return expanded
          ? Expanded(child: Align(alignment: Alignment.topLeft, child: message))
          : message;
    }

    if (expanded) {
      // Full-screen: a vertical, scrollable list of full-width cards.
      return Expanded(
        child: ListView.separated(
          padding: EdgeInsets.only(bottom: 12.h),
          itemCount: nearbyStations.length,
          separatorBuilder: (_, __) => 10.verticalSpace,
          itemBuilder: (context, index) =>
              HomeStationCardWidget(nearbyStations[index]),
        ),
      );
    }

    // Compact: a single horizontal row of fixed-width cards.
    return SizedBox(
      height: 158.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: nearbyStations.length,
        separatorBuilder: (_, __) => 8.horizontalSpace,
        itemBuilder: (context, index) => SizedBox(
          width: 280.w,
          child: HomeStationCardWidget(
            nearbyStations[index],
            isHorizontal: true,
          ),
        ),
      ),
    );
  }
}

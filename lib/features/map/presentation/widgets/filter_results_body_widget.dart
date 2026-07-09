import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_state.dart';
import 'package:orko_hubco/features/map/presentation/widgets/filter_station_card_widget.dart';

/// Body of the filter results sheet: swaps between loading, error, empty and
/// the scrollable list of matching stations based on [state].
class FilterResultsBodyWidget extends StatelessWidget {
  const FilterResultsBodyWidget({
    super.key,
    required this.state,
    required this.filtered,
    required this.hasActiveFilters,
    required this.onRetry,
    required this.onStationTap,
  });

  final MapState state;
  final List<HubcoLocationEntity> filtered;

  /// Whether any client-side chip filter is active — tunes the empty message.
  final bool hasActiveFilters;
  final VoidCallback onRetry;
  final ValueChanged<HubcoLocationEntity> onStationTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final state = this.state;

    if (state is MapLoading || state is MapInitial) {
      return Center(child: CircularProgressIndicator(color: ui.brandPrimary));
    }

    if (state is MapError) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppText(
              state.message,
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight500,
              textAlign: TextAlign.center,
              maxLines: 3,
            ),
            12.verticalSpace,
            GestureDetector(
              onTap: onRetry,
              behavior: HitTestBehavior.opaque,
              child: AppText(
                'Retry',
                color: ui.brandPrimary,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      );
    }

    if (filtered.isEmpty) {
      return Align(
        alignment: Alignment.topLeft,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: AppText(
            hasActiveFilters
                ? 'No stations match the selected filters'
                : 'No stations match your filters',
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: EdgeInsets.only(bottom: 12.h),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => 10.verticalSpace,
      itemBuilder: (context, index) {
        final station = filtered[index];
        return FilterStationCardWidget(
          station,
          onTap: () => onStationTap(station),
        );
      },
    );
  }
}

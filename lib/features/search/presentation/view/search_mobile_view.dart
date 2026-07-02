import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/search/domain/entities/station_result_entity.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_cubit.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_state.dart';
import 'package:orko_hubco/features/search/presentation/widgets/recent_search_item_widget.dart';
import 'package:orko_hubco/features/search/presentation/widgets/search_bar_widget.dart';
import 'package:orko_hubco/features/search/presentation/widgets/search_section_title_widget.dart';
import 'package:orko_hubco/features/search/presentation/widgets/station_card_widget.dart';

class SearchMobileView extends StatelessWidget {
  const SearchMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);

    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: AppUtils.horizontal16Padding,
              child: Column(
                children: [
                  8.verticalSpace,
                  const SearchBarWidget(),
                ],
              ),
            ),
            Expanded(
              child: BlocBuilder<SearchCubit, SearchState>(
                builder: (context, state) {
                  return ListView(
                    padding: AppUtils.horizontal16Padding,
                    children: state.isSearching
                        ? _buildResults(context, state)
                        : _buildIdle(context, state),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Idle layout: recent searches + popular stations ───────────────────
  List<Widget> _buildIdle(BuildContext context, SearchState state) {
    final ui = AppUiColors.of(context);
    final cubit = context.read<SearchCubit>();

    return [
      16.verticalSpace,
      if (state.recentSearches.isNotEmpty) ...[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SearchSectionTitleWidget(title: 'Recent Searches'),
            InkWell(
              onTap: cubit.clearRecentSearches,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 4.h, horizontal: 4.w),
                child: AppText(
                  'Clear All',
                  color: AppColors.maroonColor,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                ),
              ),
            ),
          ],
        ),
        10.verticalSpace,
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: state.recentSearches.length,
          separatorBuilder: (_, __) => 14.verticalSpace,
          itemBuilder: (context, index) {
            final query = state.recentSearches[index].query;
            return RecentSearchItemWidget(
              text: query,
              onTap: () => cubit.searchFromRecent(query),
              onRemove: () => cubit.removeRecentSearch(query),
            );
          },
        ),
        18.verticalSpace,
        Divider(color: ui.borderSubtle),
        16.verticalSpace,
      ],
      const SearchSectionTitleWidget(
        title: 'Popular Stations',
        leadingIcon: Icons.local_fire_department_rounded,
      ),
      10.verticalSpace,
      ..._buildPopularSection(context, state),
      10.verticalSpace,
    ];
  }

  List<Widget> _buildPopularSection(BuildContext context, SearchState state) {
    final cubit = context.read<SearchCubit>();
    switch (state.popularStatus) {
      case SearchStatus.initial:
      case SearchStatus.loading:
        return [_loader()];
      case SearchStatus.failure:
        return [
          _errorState(
            context,
            message: state.popularError,
            onRetry: cubit.retryPopular,
          ),
        ];
      case SearchStatus.success:
        if (state.popularStations.isEmpty) {
          return [_emptyState(context, 'No popular stations right now.')];
        }
        return _stationList(context, state.popularStations);
    }
  }

  // ── Search results layout ─────────────────────────────────────────────
  List<Widget> _buildResults(BuildContext context, SearchState state) {
    switch (state.resultsStatus) {
      case SearchStatus.initial:
      case SearchStatus.loading:
        return [24.verticalSpace, _loader()];
      case SearchStatus.failure:
        return [24.verticalSpace, _errorState(context, message: state.resultsError)];
      case SearchStatus.success:
        if (state.results.isEmpty) {
          return [
            24.verticalSpace,
            _emptyState(context, 'No stations found for "${state.query}".'),
          ];
        }
        return [16.verticalSpace, ..._stationList(context, state.results)];
    }
  }

  // ── Shared builders ───────────────────────────────────────────────────
  List<Widget> _stationList(
    BuildContext context,
    List<StationResultEntity> stations,
  ) {
    final widgets = <Widget>[];
    for (var i = 0; i < stations.length; i++) {
      if (i > 0) widgets.add(8.verticalSpace);
      widgets.add(_stationCard(context, stations[i]));
    }
    return widgets;
  }

  Widget _stationCard(BuildContext context, StationResultEntity station) {
    return StationCardWidget(
      title: station.name,
      subtitle: station.subtitle,
      distance: AppHelpers.formatDistanceKm(station.distanceKm),
      power: station.powerLabel,
      available:
          '${station.availableConnectors}/${station.numberOfConnectors} Available',
      tags: station.tags,
      rating: station.averageRating,
      onTap: () => _openDetail(context, station),
    );
  }

  void _openDetail(BuildContext context, StationResultEntity station) {
    context.read<SearchCubit>().recordResultTap(station.name);
    // The detail page is keyed off a HubcoLocationEntity; map across the fields
    // the search/popular result provides (it re-fetches the rest by id).
    final extra = HubcoLocationEntity(
      id: station.id,
      name: station.name,
      address: station.subtitle,
      latitude: station.latitude,
      longitude: station.longitude,
      status: station.available,
      distance: station.distanceKm,
      numberOfConnectors: station.numberOfConnectors,
      availableConnectors: station.availableConnectors,
      available: station.available,
      connectorTypes: station.powerTypes,
    );
    context.push('/station-detail', extra: extra);
  }

  Widget _loader() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Center(
        child: SizedBox(
          width: 28.r,
          height: 28.r,
          child: const CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }

  Widget _emptyState(BuildContext context, String message) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 32.h),
      child: Center(
        child: AppText(
          message,
          color: ui.textMuted,
          fontSize: FontSizes.font14Sp,
          fontWeight: FontWeights.weight400,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _errorState(
    BuildContext context, {
    required String message,
    VoidCallback? onRetry,
  }) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 28.h),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: ui.textMuted, size: 28.sp),
          10.verticalSpace,
          AppText(
            message.isEmpty ? 'Something went wrong.' : message,
            color: ui.textMuted,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            12.verticalSpace,
            InkWell(
              onTap: onRetry,
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h, horizontal: 16.w),
                child: AppText(
                  'Retry',
                  color: AppColors.primaryDarkColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

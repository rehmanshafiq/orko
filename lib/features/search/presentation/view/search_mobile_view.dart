import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_cubit.dart';
import 'package:orko_hubco/features/search/presentation/widgets/recent_search_item_widget.dart';
import 'package:orko_hubco/features/search/presentation/widgets/search_bar_widget.dart';
import 'package:orko_hubco/features/search/presentation/widgets/search_section_title_widget.dart';
import 'package:orko_hubco/features/search/presentation/widgets/station_card_widget.dart';

class SearchMobileView extends StatelessWidget {
  const SearchMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return BlocProvider(
      create: (_) => SearchCubit(),
      child: Scaffold(
        backgroundColor: ui.scaffoldBackground,
        body: SafeArea(
          child: ListView(
            padding: AppUtils.horizontal16Padding,
            children: [
              8.verticalSpace,
              const SearchBarWidget(),
              16.verticalSpace,
              const SearchSectionTitleWidget(title: 'Recent Searches'),
              10.verticalSpace,
              const RecentSearchItemWidget(text: 'Lahore Motorway M2'),
              14.verticalSpace,
              const RecentSearchItemWidget(text: 'DHA Phase 5 Lahore'),
              14.verticalSpace,
              const RecentSearchItemWidget(text: 'Islamabad Blue Area'),
              18.verticalSpace,
              Divider(color: ui.borderSubtle),
              16.verticalSpace,
              const SearchSectionTitleWidget(
                title: 'Popular Stations',
                leadingIcon: Icons.local_fire_department_rounded,
              ),
              10.verticalSpace,
              const StationCardWidget(
                title: 'HGL Liberty Market',
                subtitle: 'Lahore',
                distance: '1.2 km',
                available: '4/6 Available',
                tags: ['DC Fast', 'CCS2'],
              ),
              8.verticalSpace,
              const StationCardWidget(
                title: 'HGL Packages Mall',
                subtitle: 'Lahore',
                distance: '2.8 km',
                available: '0/4 Available',
                tags: ['DC Fast', 'CHAdeMO'],
              ),
              8.verticalSpace,
              const StationCardWidget(
                title: 'HGL Blue Area Islamabad',
                subtitle: 'Islamabad',
                distance: '4.5 km',
                available: '6/8 Available',
                tags: ['AC Level 2', 'Type 2'],
              ),
              10.verticalSpace,
            ],
          ),
        ),
      ),
    );
  }
}


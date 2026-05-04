import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: ListView(
          padding: AppUtils.horizontal16Padding,
          children: [
            8.verticalSpace,
            _searchBar(context),
            16.verticalSpace,
            _sectionTitle(context, 'Recent Searches'),
            10.verticalSpace,
            _recentItem(context, 'Lahore Motorway M2'),
            14.verticalSpace,
            _recentItem(context, 'DHA Phase 5 Lahore'),
            14.verticalSpace,
            _recentItem(context, 'Islamabad Blue Area'),
            18.verticalSpace,
            Divider(color: ui.borderSubtle),
            16.verticalSpace,
            _sectionTitle(
              context,
              'Popular Stations',
              leadingIcon: Icons.local_fire_department_rounded,
            ),
            10.verticalSpace,
            _stationCard(
              context: context,
              title: 'HGL Liberty Market',
              subtitle: 'Lahore',
              distance: '1.2 km',
              available: '4/6 Available',
              tags: const ['DC Fast', 'CCS2'],
            ),
            8.verticalSpace,
            _stationCard(
              context: context,
              title: 'HGL Packages Mall',
              subtitle: 'Lahore',
              distance: '2.8 km',
              available: '0/4 Available',
              tags: const ['DC Fast', 'CHAdeMO'],
            ),
            8.verticalSpace,
            _stationCard(
              context: context,
              title: 'HGL Blue Area Islamabad',
              subtitle: 'Islamabad',
              distance: '4.5 km',
              available: '6/8 Available',
              tags: const ['AC Level 2', 'Type 2'],
            ),
            10.verticalSpace,
          ],
        ),
      ),
    );
  }

  Widget _searchBar(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      height: 52.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.primaryDarkColor, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDarkColor.withValues(alpha: 0.25),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Material(
            color: AppColors.transparentColor,
            child: InkWell(
              onTap: () => context.pop(),
              customBorder: const CircleBorder(),
              child: Icon(
                Icons.arrow_back_rounded,
                color: ui.textPrimary.withValues(alpha: 0.8),
                size: 18.r,
              ),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            child: TextField(
              controller: _searchController,
              cursorColor: AppColors.primaryDarkColor,
              style: TextStyle(
                color: ui.textPrimary,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight400,
                fontFamily: AppFonts.lexend,
                height: 1.0,
              ),
              strutStyle: StrutStyle(
                fontSize: FontSizes.font12Sp,
                height: 1.0,
                fontFamily: AppFonts.lexend,
                forceStrutHeight: true,
              ),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Search stations or locations',
                hintStyle: TextStyle(
                  color: ui.textMuted,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                  fontFamily: AppFonts.lexend,
                  height: 1.0,
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
              minLines: 1,
              maxLines: 1,
              textAlignVertical: TextAlignVertical.center,
            ),
          ),
          8.horizontalSpace,
          Material(
            color: AppColors.transparentColor,
            child: InkWell(
              onTap: () {
                _searchController.clear();
                context.pop();
              },
              customBorder: const CircleBorder(),
              child: Icon(
                Icons.close_rounded,
                color: ui.textMuted,
                size: 18.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, {IconData? leadingIcon}) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: AppColors.maroonColor, size: 16.sp),
          6.horizontalSpace,
        ],
        AppText(
          title,
          color: ui.textPrimary,
          fontSize: FontSizes.font20Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }

  Widget _recentItem(BuildContext context, String text) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        Icon(Icons.access_time_rounded, color: ui.textMuted, size: 16.sp),
        10.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            color: ui.textPrimary.withValues(alpha: 0.9),
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
          ),
        ),
        10.horizontalSpace,
        Icon(Icons.arrow_forward_ios_rounded, color: ui.textMuted, size: 13.sp),
      ],
    );
  }

  Widget _stationCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String distance,
    required String available,
    required List<String> tags,
  }) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.homeStationCardPadding,
      decoration: BoxDecoration(
        color: ui.cardBackground.withValues(alpha: ui.isLight ? 1 : 0.9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: AppText(
                        title,
                        color: ui.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    5.horizontalSpace,
                    AppText(
                      subtitle,
                      color: ui.textMuted,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              _distanceChip(context, distance),
            ],
          ),
          4.verticalSpace,
          AppText(
            available,
            color: AppColors.primaryLightColor,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
          6.verticalSpace,
          Row(
            children: [
              Icon(Icons.ev_station_outlined, color: ui.textMuted, size: 13.sp),
              6.horizontalSpace,
              Icon(Icons.bolt_outlined, color: ui.textMuted, size: 13.sp),
              8.horizontalSpace,
              _tagChip(context, tags[0]),
              4.horizontalSpace,
              _tagChip(context, tags[1]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _distanceChip(BuildContext context, String text) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.navigation_rounded, color: ui.textSecondary, size: 10.sp),
          4.horizontalSpace,
          AppText(
            text,
            color: ui.textPrimary,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }

  Widget _tagChip(BuildContext context, String label) {
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: AppText(
        label,
        color: ui.textPrimary.withValues(alpha: 0.85),
        fontSize: FontSizes.font8Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}

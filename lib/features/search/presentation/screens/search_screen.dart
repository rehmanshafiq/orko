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
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: ListView(
          padding: AppUtils.horizontal16Padding,
          children: [
            8.verticalSpace,
            _searchBar(context),
            16.verticalSpace,
            _sectionTitle('Recent Searches'),
            10.verticalSpace,
            _recentItem('Lahore Motorway M2'),
            14.verticalSpace,
            _recentItem('DHA Phase 5 Lahore'),
            14.verticalSpace,
            _recentItem('Islamabad Blue Area'),
            18.verticalSpace,
            Divider(color: AppColors.whiteColor.withValues(alpha: 0.10)),
            16.verticalSpace,
            _sectionTitle('Popular Stations', leadingIcon: Icons.local_fire_department_rounded),
            10.verticalSpace,
            _stationCard(
              title: 'HGL Liberty Market',
              subtitle: 'Lahore',
              distance: '1.2 km',
              available: '4/6 Available',
              tags: const ['DC Fast', 'CCS2'],
            ),
            8.verticalSpace,
            _stationCard(
              title: 'HGL Packages Mall',
              subtitle: 'Lahore',
              distance: '2.8 km',
              available: '0/4 Available',
              tags: const ['DC Fast', 'CHAdeMO'],
            ),
            8.verticalSpace,
            _stationCard(
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
    return Container(
      height: 52.h,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
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
                color: AppColors.whiteColor.withValues(alpha: 0.8),
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
                color: AppColors.whiteColor,
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
                  color: AppColors.whiteColor.withValues(alpha: 0.65),
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
                color: AppColors.whiteColor.withValues(alpha: 0.65),
                size: 18.r,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, {IconData? leadingIcon}) {
    return Row(
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, color: AppColors.maroonColor, size: 16.sp),
          6.horizontalSpace,
        ],
        AppText(
          title,
          color: AppColors.whiteColor,
          fontSize: FontSizes.font20Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }

  Widget _recentItem(String text) {
    return Row(
      children: [
        Icon(Icons.access_time_rounded, color: AppColors.whiteColor.withValues(alpha: 0.55), size: 16.sp),
        10.horizontalSpace,
        Expanded(
          child: AppText(
            text,
            color: AppColors.whiteColor.withValues(alpha: 0.9),
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
          ),
        ),
        10.horizontalSpace,
        Icon(Icons.arrow_forward_ios_rounded, color: AppColors.whiteColor.withValues(alpha: 0.55), size: 13.sp),
      ],
    );
  }

  Widget _stationCard({
    required String title,
    required String subtitle,
    required String distance,
    required String available,
    required List<String> tags,
  }) {
    return Container(
      padding: AppUtils.homeStationCardPadding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppColors.whiteColor.withValues(alpha: 0.08)),
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
                        color: AppColors.whiteColor,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    5.horizontalSpace,
                    AppText(
                      subtitle,
                      color: AppColors.whiteColor.withValues(alpha: 0.45),
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
              8.horizontalSpace,
              _distanceChip(distance),
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
              Icon(Icons.ev_station_outlined, color: AppColors.whiteColor.withValues(alpha: 0.5), size: 13.sp),
              6.horizontalSpace,
              Icon(Icons.bolt_outlined, color: AppColors.whiteColor.withValues(alpha: 0.5), size: 13.sp),
              8.horizontalSpace,
              _tagChip(tags[0]),
              4.horizontalSpace,
              _tagChip(tags[1]),
            ],
          ),
        ],
      ),
    );
  }

  Widget _distanceChip(String text) {
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(Icons.navigation_rounded, color: AppColors.whiteColor.withValues(alpha: 0.75), size: 10.sp),
          4.horizontalSpace,
          AppText(
            text,
            color: AppColors.whiteColor,
            fontSize: FontSizes.font8Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }

  Widget _tagChip(String label) {
    return Container(
      padding: AppUtils.horizontal8Vertical4Padding,
      decoration: BoxDecoration(
        color: AppColors.whiteColor.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: AppText(
        label,
        color: AppColors.whiteColor.withValues(alpha: 0.85),
        fontSize: FontSizes.font8Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/features/search/presentation/cubit/search_cubit.dart';

class SearchBarWidget extends StatelessWidget {
  const SearchBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final searchCubit = context.read<SearchCubit>();

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
                size: 19.r,
              ),
            ),
          ),
          8.horizontalSpace,
          Expanded(
            child: TextField(
              controller: searchCubit.searchController,
              onChanged: searchCubit.onQueryChanged,
              onSubmitted: (_) => searchCubit.submitSearch(),
              textInputAction: TextInputAction.search,
              autofocus: true,
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
                searchCubit.clearSearch();
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
}


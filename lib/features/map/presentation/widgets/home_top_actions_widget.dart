import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/presentation/widgets/map_filters_bottom_sheet.dart';
import 'package:orko_hubco/features/map/presentation/widgets/notification_bell_widget.dart';
import 'package:orko_hubco/features/map/presentation/widgets/top_action_icon_widget.dart';

/// Home top bar: tap-to-search field with an inline filter button, plus the
/// notification bell.
class HomeTopActionsWidget extends StatelessWidget {
  const HomeTopActionsWidget({
    super.key,
    required this.stationCount,
    required this.unreadCount,
    required this.onNotificationsTap,
  });

  /// Station count forwarded to the filters bottom sheet.
  final int stationCount;
  final int unreadCount;
  final VoidCallback onNotificationsTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        Expanded(
          child: Material(
            color: AppColors.transparentColor,
            child: InkWell(
              onTap: () => context.push('/search'),
              borderRadius: BorderRadius.circular(10.r),
              child: Ink(
                padding: AppUtils.homeTopSearchPadding,
                decoration: BoxDecoration(
                  color: ui.searchBackground,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: ui.borderSubtle),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: ui.textMuted, size: 25),
                    8.horizontalSpace,
                    Expanded(
                      child: AppText(
                        'Search stations or locations',
                        color: ui.textMuted,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ),
                    8.horizontalSpace,
                    TopActionIconWidget(
                      Icons.tune_rounded,
                      isPrimary: true,
                      isCompact: true,
                      onTap: () => MapFiltersBottomSheet.show(
                        context,
                        stationCount: stationCount,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        10.horizontalSpace,
        NotificationBellWidget(
          unreadCount: unreadCount,
          onTap: onNotificationsTap,
        ),
      ],
    );
  }
}

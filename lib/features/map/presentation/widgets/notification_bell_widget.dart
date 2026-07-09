import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/map/presentation/widgets/top_action_icon_widget.dart';

/// Notification bell with an unread-count badge overlay. The badge is hidden
/// when [unreadCount] is 0 and capped at `99+`.
class NotificationBellWidget extends StatelessWidget {
  const NotificationBellWidget({
    super.key,
    required this.unreadCount,
    required this.onTap,
  });

  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bell = TopActionIconWidget(
      Icons.notifications_none_rounded,
      onTap: onTap,
    );

    if (unreadCount <= 0) return bell;

    final ui = AppUiColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        bell,
        Positioned(
          right: -2,
          top: -2,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            constraints: BoxConstraints(minWidth: 18.r),
            decoration: BoxDecoration(
              color: AppColors.removeColor,
              borderRadius: BorderRadius.circular(20.r),
              border: Border.all(color: ui.scaffoldBackground, width: 1.5),
            ),
            alignment: Alignment.center,
            child: AppText(
              unreadCount > 99 ? '99+' : '$unreadCount',
              color: AppColors.whiteColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight700,
            ),
          ),
        ),
      ],
    );
  }
}

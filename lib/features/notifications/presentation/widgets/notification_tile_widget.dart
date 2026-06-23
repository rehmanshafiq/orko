import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_entity.dart';

/// A single notification row. Unread items get a tinted background, a leading
/// accent dot, and bolder text; tapping marks them read.
class NotificationTileWidget extends StatelessWidget {
  const NotificationTileWidget({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationEntity notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final unread = !notification.isRead;

    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          padding: AppUtils.vertical10Horizontal12Padding,
          decoration: BoxDecoration(
            color: unread
                ? ui.brandPrimary.withValues(alpha: ui.isLight ? 0.06 : 0.12)
                : ui.searchBackground,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(
              color: unread
                  ? ui.brandPrimary.withValues(alpha: 0.35)
                  : ui.borderSubtle,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.only(top: 6.h),
                child: Container(
                  height: 8.r,
                  width: 8.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unread ? ui.brandPrimary : AppColors.transparentColor,
                    border: unread
                        ? null
                        : Border.all(color: ui.textMuted.withValues(alpha: 0.4)),
                  ),
                ),
              ),
              12.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: AppText(
                            notification.title.isEmpty
                                ? 'Notification'
                                : notification.title,
                            color: ui.textPrimary,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: unread
                                ? FontWeights.weight700
                                : FontWeights.weight500,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        8.horizontalSpace,
                        AppText(
                          _relativeTime(notification.displayTimestamp),
                          color: ui.textMuted,
                          fontSize: FontSizes.font10Sp,
                          fontWeight: FontWeights.weight400,
                        ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      4.verticalSpace,
                      AppText(
                        notification.body,
                        color: ui.textSecondary,
                        fontSize: FontSizes.font12Sp,
                        fontWeight: FontWeights.weight400,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Compact relative time from epoch seconds (e.g. "Just now", "3h", "2d").
  /// Falls back to an absolute date for anything older than a week.
  String _relativeTime(int epochSeconds) {
    if (epochSeconds <= 0) return '';
    final then = DateTime.fromMillisecondsSinceEpoch(epochSeconds * 1000);
    final diff = DateTime.now().difference(then);

    if (diff.isNegative) return 'Just now';
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${then.day} ${months[then.month - 1]}';
  }
}

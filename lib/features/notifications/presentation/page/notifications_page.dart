import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notifications_state.dart';
import 'package:orko_hubco/features/notifications/presentation/widgets/notification_tile_widget.dart';

/// Lists the user's notifications (`GET /api/v1/notifications/`), newest first,
/// with pull-to-refresh, infinite scroll, mark-one-read, and mark-all-read.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<NotificationsCubit>()..loadInitial(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatefulWidget {
  const _NotificationsView();

  @override
  State<_NotificationsView> createState() => _NotificationsViewState();
}

class _NotificationsViewState extends State<_NotificationsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    // Trigger a page ahead of the very bottom for a seamless scroll.
    if (position.pixels >= position.maxScrollExtent - 320) {
      context.read<NotificationsCubit>().loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ui.scaffoldBackground,
        elevation: 0,
        iconTheme: IconThemeData(color: ui.textPrimary),
        title: AppText(
          'Notifications',
          color: ui.textPrimary,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
        actions: [
          BlocBuilder<NotificationsCubit, NotificationsState>(
            buildWhen: (p, c) =>
                p.unreadCount != c.unreadCount ||
                p.markingAll != c.markingAll ||
                p.status != c.status,
            builder: (context, state) {
              final canMarkAll = state.status == NotificationsStatus.success &&
                  (state.unreadCount > 0 ||
                      state.notifications.any((n) => !n.isRead));
              if (!canMarkAll) return const SizedBox.shrink();
              return TextButton(
                onPressed: state.markingAll
                    ? null
                    : () => context.read<NotificationsCubit>().markAllAsRead(),
                child: AppText(
                  state.markingAll ? 'Marking…' : 'Mark all read',
                  color: state.markingAll ? ui.textMuted : ui.brandPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight700,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocConsumer<NotificationsCubit, NotificationsState>(
          listenWhen: (p, c) =>
              p.actionError != c.actionError && c.actionError != null,
          listener: (context, state) {
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(state.actionError!),
                  backgroundColor: AppColors.removeColor,
                  behavior: SnackBarBehavior.floating,
                ),
              );
          },
          builder: (context, state) => _body(context, ui, state),
        ),
      ),
    );
  }

  Widget _body(BuildContext context, AppUiColors ui, NotificationsState state) {
    final cubit = context.read<NotificationsCubit>();

    switch (state.status) {
      case NotificationsStatus.initial:
      case NotificationsStatus.loading:
        return Center(child: CircularProgressIndicator(color: ui.brandPrimary));

      case NotificationsStatus.failure:
        return _ErrorState(
          message: state.errorMessage ?? 'Could not load your notifications.',
          onRetry: cubit.loadInitial,
        );

      case NotificationsStatus.success:
        if (state.notifications.isEmpty) {
          // Empty but still refreshable (pull down to re-check).
          return RefreshIndicator(
            color: ui.brandPrimary,
            onRefresh: cubit.refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                SizedBox(height: 0.6.sh),
                Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 32.w),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.notifications_none_rounded,
                          size: 48.sp,
                          color: ui.textMuted,
                        ),
                        12.verticalSpace,
                        AppText(
                          'You\'re all caught up',
                          color: ui.textPrimary,
                          fontSize: FontSizes.font15Sp,
                          fontWeight: FontWeights.weight700,
                          textAlign: TextAlign.center,
                        ),
                        6.verticalSpace,
                        AppText(
                          'No notifications yet. We\'ll let you know when something happens.',
                          color: ui.textMuted,
                          fontSize: FontSizes.font12Sp,
                          fontWeight: FontWeights.weight400,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          color: ui.brandPrimary,
          onRefresh: cubit.refresh,
          child: ListView.separated(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
            itemCount: state.notifications.length + 1,
            separatorBuilder: (_, __) => 10.verticalSpace,
            itemBuilder: (context, index) {
              if (index == state.notifications.length) {
                return _Footer(state: state);
              }
              final notification = state.notifications[index];
              return NotificationTileWidget(
                notification: notification,
                onTap: () => cubit.markAsRead(notification.id),
              );
            },
          ),
        );
    }
  }
}

/// Bottom-of-list footer: a spinner while paginating, otherwise nothing.
class _Footer extends StatelessWidget {
  const _Footer({required this.state});

  final NotificationsState state;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    if (state.isLoadingMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: SizedBox(
            height: 22.r,
            width: 22.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: ui.brandPrimary,
            ),
          ),
        ),
      );
    }
    if (!state.hasMore && state.notifications.isNotEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Center(
          child: AppText(
            'That\'s everything',
            color: ui.textMuted,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_rounded,
              size: 44.sp,
              color: ui.textMuted,
            ),
            12.verticalSpace,
            AppText(
              message,
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight500,
              textAlign: TextAlign.center,
            ),
            12.verticalSpace,
            TextButton(
              onPressed: onRetry,
              child: AppText(
                'Retry',
                color: ui.brandPrimary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

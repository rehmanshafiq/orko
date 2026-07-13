import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/gradient_switch.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notification_preferences_state.dart';

/// Full-screen notification preferences page backed by the preferences API
/// (`GET/PATCH /api/v1/notifications/preferences/`). Each toggle is optimistic
/// and reverts on failure; rows lock individually while their PATCH is in
/// flight. Guests are shown a sign-in prompt.
class NotificationPreferencesPage extends StatelessWidget {
  const NotificationPreferencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      appBar: AppBar(
        backgroundColor: ui.scaffoldBackground,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_rounded, color: ui.textPrimary),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: AppText(
          'Notifications',
          color: ui.textPrimary,
          fontSize: FontSizes.font18Sp,
          fontWeight: FontWeights.weight700,
        ),
        centerTitle: false,
      ),
      body: SafeArea(
        child: AppStorage.isGuest
            ? _GuestMessage(ui: ui)
            : BlocProvider(
                create: (_) => sl<NotificationPreferencesCubit>()..load(),
                child: const _NotificationPreferencesBody(),
              ),
      ),
    );
  }
}

class _GuestMessage extends StatelessWidget {
  const _GuestMessage({required this.ui});

  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppUtils.horizontal16Padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_off_outlined,
            color: ui.textSecondary,
            size: 48.r,
          ),
          16.verticalSpace,
          AppText(
            'Sign in to manage your notification preferences.',
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
          ),
        ],
      ),
    );
  }
}

class _NotificationPreferencesBody extends StatelessWidget {
  const _NotificationPreferencesBody();

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return BlocConsumer<NotificationPreferencesCubit,
        NotificationPreferencesState>(
      listenWhen: (p, c) =>
          p.actionError != c.actionError && c.actionError != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(state.actionError!),
              backgroundColor: AppColors.removeColor,
            ),
          );
      },
      builder: (context, state) {
        return SingleChildScrollView(
          padding: AppUtils.horizontal16Padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              16.verticalSpace,
              _buildBody(context, ui, state),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppUiColors ui,
    NotificationPreferencesState state,
  ) {
    final cubit = context.read<NotificationPreferencesCubit>();

    switch (state.status) {
      case NotificationPreferencesStatus.initial:
      case NotificationPreferencesStatus.loading:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: SizedBox(
              width: 26.w,
              height: 26.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: ui.brandPrimary,
              ),
            ),
          ),
        );

      case NotificationPreferencesStatus.failure:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 24.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                state.errorMessage ?? 'Could not load notification settings.',
                color: ui.textSecondary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight400,
              ),
              8.verticalSpace,
              GestureDetector(
                onTap: cubit.load,
                behavior: HitTestBehavior.opaque,
                child: AppText(
                  'Retry',
                  color: ui.brandPrimary,
                  fontSize: FontSizes.font13Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
            ],
          ),
        );

      case NotificationPreferencesStatus.success:
        final prefs = state.preferences;
        ValueChanged<bool>? handlerFor(NotificationPreferenceKey key) =>
            state.isUpdating(key)
                ? null
                : (value) => cubit.toggle(key, value);

        return Container(
          width: double.infinity,
          padding: AppUtils.all18Padding,
          decoration: BoxDecoration(
            color: ui.vehicleImagePlaceholder,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: ui.borderSubtle),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _NotificationRow(
                title: 'Charging Updates',
                subtitle: 'Get notified about charging status',
                value: prefs.chargingUpdates,
                onChanged:
                    handlerFor(NotificationPreferenceKey.chargingUpdates),
              ),
              _DividerLine(ui: ui),
              _NotificationRow(
                title: 'Booking Reminders',
                subtitle: 'Reminders for upcoming bookings',
                value: prefs.bookingReminders,
                onChanged:
                    handlerFor(NotificationPreferenceKey.bookingReminders),
              ),
              _DividerLine(ui: ui),
              _NotificationRow(
                title: 'Promotional Offers',
                subtitle: 'Special deals and discounts',
                value: prefs.promotionalOffers,
                onChanged:
                    handlerFor(NotificationPreferenceKey.promotionalOffers),
              ),
              _DividerLine(ui: ui),
              _NotificationRow(
                title: 'App Updates',
                subtitle: 'New features',
                value: prefs.appUpdates,
                onChanged: handlerFor(NotificationPreferenceKey.appUpdates),
              ),
            ],
          ),
        );
    }
  }
}

class _DividerLine extends StatelessWidget {
  const _DividerLine({required this.ui});

  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, thickness: 1, color: ui.borderSubtle);
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;

  /// Null disables the row (e.g. while its PATCH is in flight).
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  title,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight600,
                ),
                4.verticalSpace,
                AppText(
                  subtitle,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ],
            ),
          ),
          8.horizontalSpace,
          GradientSwitch(
            value: value,
            onChanged: onChanged,
            gradientColors: const [
              AppColors.primaryDarkColor,
              AppColors.primaryDarkButtonColor,
            ],
          ),
        ],
      ),
    );
  }
}

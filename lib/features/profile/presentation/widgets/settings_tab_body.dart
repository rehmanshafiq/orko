import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/core/theme/theme_cubit.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/app_web_view_page.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';
import 'package:orko_hubco/features/notifications/presentation/page/notification_preferences_page.dart';
import 'package:orko_hubco/features/profile/presentation/page/help_support_page.dart';
import 'package:orko_hubco/features/profile/presentation/utils/profile_actions.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/section_card.dart';

/// Opens the privacy policy (from Remote Config) in an in-app WebView. Falls
/// back to a toast when Remote Config carries no URL yet.
void _openPrivacyPolicy(BuildContext context) {
  final url =
      RemoteConfigService.config?.apiConstants.privacyPolicyUrl.trim() ?? '';
  if (url.isEmpty) {
    Fluttertoast.showToast(
      msg: 'Privacy policy is currently unavailable',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => AppWebViewPage(
        url: url,
        title: 'Privacy & Security',
      ),
    ),
  );
}

/// Body of the "Settings" main tab: appearance switcher and account entries.
class SettingsTabBody extends StatelessWidget {
  const SettingsTabBody({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final storage = sl<LocalStorageService>();
    final cachedUser = readCachedUser(storage);
    final isGuest = storage.isGuest || cachedUser == null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppearanceSection(),
        14.verticalSpace,
        SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppText(
                'Account',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
              10.verticalSpace,
              AccountTile(
                icon: Icons.person_outline_rounded,
                label: 'Edit Profile',
                onTap: () => openEditProfile(context, cachedUser, isGuest),
              ),
              const DividerLine(),
              AccountTile(
                icon: Icons.notifications_outlined,
                label: 'Notifications',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const NotificationPreferencesPage(),
                  ),
                ),
              ),
              const DividerLine(),
              AccountTile(
                icon: Icons.shield_outlined,
                label: 'Privacy & Security',
                onTap: () => _openPrivacyPolicy(context),
              ),
              const DividerLine(),
              AccountTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const HelpSupportPage(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Light / Dark theme switcher card.
class AppearanceSection extends StatelessWidget {
  const AppearanceSection({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final themeCubit = context.read<ThemeCubit>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.brightness_6_outlined,
                color: ui.textMuted,
                size: 20.r,
              ),
              8.horizontalSpace,
              AppText(
                'Appearance',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: PrimaryButtonWidget(
                  text: 'Light',
                  onPress: themeCubit.setLight,
                  buttonHeight: 38.h,
                  cornerRadius: 24.r,
                  buttonColor: !isLight
                      ? AppColors.whiteColor.withValues(alpha: 0.12)
                      : null,
                  gradientColors: isLight
                      ? [
                          AppColors.primaryDarkColor,
                          AppColors.primaryDarkButtonColor,
                        ]
                      : null,
                  strokeColor: isLight ? null : ui.borderSubtle,
                  textColor: AppColors.whiteColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: PrimaryButtonWidget(
                  text: 'Dark',
                  onPress: themeCubit.setDark,
                  buttonHeight: 38.h,
                  cornerRadius: 24.r,
                  buttonColor: isLight
                      ? AppColors.whiteColor.withValues(alpha: 0.12)
                      : null,
                  gradientColors: !isLight
                      ? [
                          AppColors.primaryDarkColor,
                          AppColors.primaryDarkButtonColor,
                        ]
                      : null,
                  strokeColor: !isLight ? null : ui.borderSubtle,
                  textColor: AppColors.whiteColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Selectable language pill (currently unused — kept for the upcoming
/// language setting).
class LanguageChip extends StatelessWidget {
  const LanguageChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: selected ? ui.brandPrimary : ui.chipInactiveBg,
            borderRadius: BorderRadius.circular(10.r),
            border: Border.all(
              color: selected ? ui.brandPrimary : ui.chipInactiveBorder,
            ),
          ),
          alignment: Alignment.center,
          child: AppText(
            label,
            color: selected
                ? (AppColors.whiteColor)
                : ui.textPrimary.withValues(alpha: 0.88),
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight600,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Chevron row inside the Account card.
class AccountTile extends StatelessWidget {
  const AccountTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8.r),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            children: [
              Icon(icon, color: ui.textMuted, size: 22.r),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  label,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight500,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: ui.textSecondary,
                size: 22.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

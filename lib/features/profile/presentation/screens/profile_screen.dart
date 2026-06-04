import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_revamped_theme.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/theme/theme_cubit.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';

/// Account profile hub: header with tabs, profile / vehicles / settings bodies.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: t.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return Center(
                child: CircularProgressIndicator(
                  color: t.brandGreen,
                  strokeWidth: 2.5,
                ),
              );
            }

            if (state is ProfileError) {
              return Padding(
                padding: AppUtils.horizontal16Padding,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_off_outlined,
                      color: ui.textSecondary,
                      size: 48.r,
                    ),
                    16.verticalSpace,
                    AppText(
                      state.message,
                      color: ui.textPrimary.withValues(alpha: 0.85),
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight400,
                      textAlign: TextAlign.center,
                    ),
                    24.verticalSpace,
                    _GradientButton(
                      text: 'Retry',
                      onPressed: () =>
                          context.read<ProfileCubit>().loadProfile(),
                      height: 48.h,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileLoaded) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _ProfileHeader(state: state),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: AppUtils.horizontal16Padding,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          16.verticalSpace,
                          if (state.mainTab == ProfileMainTab.profile)
                            _ProfileTabBody(profile: state.profile),
                          if (state.mainTab == ProfileMainTab.vehicles)
                            const _VehiclesTabBody(),
                          if (state.mainTab == ProfileMainTab.settings)
                            _SettingsTabBody(state: state),
                          24.verticalSpace,
                          Center(
                            child: TextButton(
                              onPressed: () async {
                                await context.read<AuthCubit>().logout();
                                if (context.mounted) context.go('/login');
                              },
                              child: AppText(
                                'Sign out',
                                color: AppColors.removeColor,
                                fontSize: FontSizes.font14Sp,
                                fontWeight: FontWeights.weight600,
                              ),
                            ),
                          ),
                          16.verticalSpace,
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            return Center(
              child: AppText(
                'Welcome',
                color: ui.textPrimary,
                fontSize: FontSizes.font14Sp,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.state});

  final ProfileLoaded state;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final cubit = context.read<ProfileCubit>();
    final profile = state.profile;
    final bottomRadius = 20.r;
    final headerAccent = t.bookSlotDarkGreen;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [t.ecoGradientStart, t.ecoGradientEnd],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
        boxShadow: [
          BoxShadow(
            color: t.brandGreen.withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 14.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 38.r,
                    backgroundColor:
                        AppColors.whiteColor.withValues(alpha: 0.2),
                    backgroundImage: profile.avatarUrl != null
                        ? NetworkImage(profile.avatarUrl!)
                        : null,
                    child: profile.avatarUrl == null
                        ? Icon(
                            Icons.person_rounded,
                            size: 40.r,
                            color: AppColors.whiteColor,
                          )
                        : null,
                  ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: Container(
                      padding: AppUtils.all4Padding,
                      decoration: BoxDecoration(
                        color: AppColors.whiteColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: headerAccent,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 14.r,
                        color: headerAccent,
                      ),
                    ),
                  ),
                ],
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText(
                      profile.name,
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font20Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      profile.email,
                      color: AppColors.whiteColor.withValues(alpha: 0.9),
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      'Member since Jan 2024',
                      color: AppColors.whiteColor.withValues(alpha: 0.75),
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                  ],
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _HeaderTabChip(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  selected: state.mainTab == ProfileMainTab.profile,
                  onTap: () => cubit.setMainTab(ProfileMainTab.profile),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _HeaderTabChip(
                  label: 'Vehicles',
                  icon: Icons.directions_car_outlined,
                  selected: state.mainTab == ProfileMainTab.vehicles,
                  onTap: () => cubit.setMainTab(ProfileMainTab.vehicles),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _HeaderTabChip(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  selected: state.mainTab == ProfileMainTab.settings,
                  onTap: () => cubit.setMainTab(ProfileMainTab.settings),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderTabChip extends StatelessWidget {
  const _HeaderTabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.whiteColor
                : AppColors.whiteColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected
                  ? AppColors.whiteColor
                  : AppColors.whiteColor.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.r,
                color: selected ? t.brandGreen : AppColors.whiteColor,
              ),
              4.horizontalSpace,
              Flexible(
                child: AppText(
                  label,
                  color: selected ? t.brandGreen : AppColors.whiteColor,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileTabBody extends StatelessWidget {
  const _ProfileTabBody({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StatsGrid(),
        14.verticalSpace,
        _AchievementsCard(),
        14.verticalSpace,
        _PersonalInfoCard(profile: profile),
        14.verticalSpace,
        _DrivingEfficiencyCard(),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final ui = AppUiColors.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.bolt_rounded,
                iconBg: t.mintIconBackground,
                iconColor: t.brandGreen,
                value: '47',
                valueColor: ui.textPrimary,
                label: 'Total Charges',
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: _StatTile(
                icon: Icons.battery_charging_full_rounded,
                iconBg: t.mintIconBackground,
                iconColor: t.brandGreenLight,
                value: '1245',
                valueColor: t.brandGreenLight,
                label: 'kWh Charged',
              ),
            ),
          ],
        ),
        10.verticalSpace,
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.savings_outlined,
                iconBg: AppColors.ratingStarColor.withValues(alpha: 0.18),
                iconColor: AppColors.ratingStarColor,
                value: 'PKR 12,450',
                valueColor: AppColors.ratingStarColor,
                label: 'Money Saved',
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: _StatTile(
                icon: Icons.eco_outlined,
                iconBg: t.mintIconBackground,
                iconColor: t.brandGreenBright,
                value: '285 kg',
                valueColor: t.brandGreenBright,
                label: 'CO2 Reduced',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: t.stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 22.r),
          ),
          10.verticalSpace,
          AppText(
            value,
            color: valueColor,
            fontSize: FontSizes.font18Sp,
            fontWeight: FontWeights.weight700,
          ),
          4.verticalSpace,
          AppText(
            label,
            color: t.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
        ],
      ),
    );
  }
}

class _AchievementsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(
            title: 'Achievements',
            icon: Icons.workspace_premium_outlined,
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AchievementBadge(
                label: 'Early Adopter',
                icon: Icons.military_tech_rounded,
                circleColor: AppColors.ratingStarColor.withValues(alpha: 0.22),
                iconColor: AppColors.ratingStarColor,
              ),
              _AchievementBadge(
                label: 'Eco Warrior',
                icon: Icons.eco_outlined,
                circleColor: t.mintIconBackground,
                iconColor: t.brandGreen,
              ),
              _AchievementBadge(
                label: 'Road Tripper',
                icon: Icons.directions_car_filled_rounded,
                circleColor: AppColors.mapPinBlueColor.withValues(alpha: 0.18),
                iconColor: AppColors.mapPinBlueColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  const _AchievementBadge({
    required this.label,
    required this.icon,
    required this.circleColor,
    required this.iconColor,
  });

  final String label;
  final IconData icon;
  final Color circleColor;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56.r,
          height: 56.r,
          decoration: BoxDecoration(
            color: circleColor,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(icon, color: iconColor, size: 26.r),
        ),
        8.verticalSpace,
        AppText(
          label,
          color: context.revampedTheme.textSecondary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight500,
          textAlign: TextAlign.center,
          maxLines: 2,
        ),
      ],
    );
  }
}

class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.profile});

  final ProfileEntity profile;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final ui = AppUiColors.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: _SectionTitleRow(
                  title: 'Personal Information',
                  icon: Icons.badge_outlined,
                ),
              ),
              PrimaryButtonWidget(
                text: 'Edit',
                onPress: () {},
                buttonWidth: 88.w,
                buttonHeight: 36.h,
                cornerRadius: 10.r,
                buttonColor: ui.chipInactiveBg,
                strokeColor: t.brandGreen,
                textColor: t.brandGreen,
                fontSize: FontSizes.font12Sp,
                fontWeight: FontWeights.weight600,
              ),
            ],
          ),
          14.verticalSpace,
          _KeyValueRow(label: 'Full Name', value: profile.name),
          _DividerLine(),
          _KeyValueRow(label: 'Email', value: profile.email),
          if (profile.phone != null) ...[
            _DividerLine(),
            _KeyValueRow(label: 'Phone', value: profile.phone!),
          ],
        ],
      ),
    );
  }
}

class _KeyValueRow extends StatelessWidget {
  const _KeyValueRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: AppText(
              label,
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
          8.horizontalSpace,
          Expanded(
            flex: 3,
            child: AppText(
              value,
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
              textAlign: TextAlign.end,
              maxLines: 3,
            ),
          ),
        ],
      ),
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: AppUiColors.of(context).borderSubtle,
    );
  }
}

class _DrivingEfficiencyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final ui = AppUiColors.of(context);
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: t.mintIconBackground.withValues(alpha: ui.isLight ? 0.35 : 0.5),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: t.brandGreen.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionTitleRow(
            title: 'Driving Efficiency',
            icon: Icons.speed_outlined,
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Overall Efficiency',
                  color: t.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ),
              AppText(
                '92%',
                color: t.brandGreenLight,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
          8.verticalSpace,
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: 0.92,
              minHeight: 8.h,
              backgroundColor: t.progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(t.brandGreen),
            ),
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: _MiniMetric(
                  title: 'Avg. Consumption',
                  value: '15.2 kWh/100km',
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: _MiniMetric(
                  title: 'Eco Score',
                  value: 'A+',
                ),
              ),
            ],
          ),
          12.verticalSpace,
          Container(
            width: double.infinity,
            padding: AppUtils.vertical10Horizontal12Padding,
            decoration: BoxDecoration(
              color: t.subtleSurface,
              borderRadius: BorderRadius.circular(10.r),
              border: Border.all(
                color: t.brandGreen.withValues(alpha: 0.15),
              ),
            ),
            child: AppText(
              'Efficiency Tip: Maintain steady speeds on highways to improve range by up to 15%.',
              color: t.brandGreenLight,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: t.subtleSurface,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: t.stationCardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            color: t.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          6.verticalSpace,
          AppText(
            value,
            color: t.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
          ),
        ],
      ),
    );
  }
}

class _VehiclesTabBody extends StatelessWidget {
  const _VehiclesTabBody();

  static const List<_VehicleUi> _vehicles = [
    _VehicleUi(
      nickname: 'My Tesla',
      modelLine: '2023 Tesla Model 3',
      isPrimary: true,
      rangeKm: 245,
      rangeFraction: 0.72,
      capacityKwh: '75 kWh',
      efficiency: '15.2 kWh',
      charges: '47',
      totalEnergyKwh: '1245 kWh',
      chargingPatterns: null,
    ),
    _VehicleUi(
      nickname: 'City Runner',
      modelLine: '2022 Nissan Leaf',
      isPrimary: false,
      rangeKm: 168,
      rangeFraction: 0.58,
      capacityKwh: '40 kWh',
      efficiency: '16.8 kWh',
      charges: '23',
      totalEnergyKwh: '542 kWh',
      chargingPatterns: _ChargingPatternsUi(
        mostActiveDay: 'Saturday',
        preferredTime: 'Evening (6-9 PM)',
        avgDuration: '42 minutes',
        favoriteStation: 'HUBCO Clifton',
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GradientButton(
          text: 'Add New Vehicle',
          onPressed: () {},
          height: 48.h,
          fontSize: FontSizes.font15Sp,
          fontWeight: FontWeights.weight700,
        ),
        14.verticalSpace,
        ..._vehicles.map(
          (v) => Padding(
            padding: EdgeInsets.only(bottom: 14.h),
            child: _VehicleCard(vehicle: v),
          ),
        ),
      ],
    );
  }
}

class _ChargingPatternsUi {
  const _ChargingPatternsUi({
    required this.mostActiveDay,
    required this.preferredTime,
    required this.avgDuration,
    required this.favoriteStation,
  });

  final String mostActiveDay;
  final String preferredTime;
  final String avgDuration;
  final String favoriteStation;
}

class _VehicleUi {
  const _VehicleUi({
    required this.nickname,
    required this.modelLine,
    required this.isPrimary,
    required this.rangeKm,
    required this.rangeFraction,
    required this.capacityKwh,
    required this.efficiency,
    required this.charges,
    required this.totalEnergyKwh,
    this.chargingPatterns,
  });

  final String nickname;
  final String modelLine;
  final bool isPrimary;
  final int rangeKm;
  final double rangeFraction;
  final String capacityKwh;
  final String efficiency;
  final String charges;
  final String totalEnergyKwh;
  final _ChargingPatternsUi? chargingPatterns;
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({required this.vehicle});

  final _VehicleUi vehicle;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final ui = AppUiColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: t.stationCardBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              Container(
                height: 140.h,
                width: double.infinity,
                color: ui.vehicleImagePlaceholder,
                alignment: Alignment.center,
                child: Icon(
                  Icons.electric_car_rounded,
                  size: 72.r,
                  color: t.brandGreen.withValues(alpha: 0.75),
                ),
              ),
              if (vehicle.isPrimary)
                Positioned(
                  top: 10.h,
                  right: 10.w,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: t.brandGreen,
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: AppText(
                      'Primary Vehicle',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font10Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ),
                ),
            ],
          ),
          Padding(
            padding: AppUtils.all12Padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText(
                            vehicle.nickname,
                            color: ui.textPrimary,
                            fontSize: FontSizes.font16Sp,
                            fontWeight: FontWeights.weight700,
                          ),
                          4.verticalSpace,
                          AppText(
                            vehicle.modelLine,
                            color: ui.textSecondary,
                            fontSize: FontSizes.font12Sp,
                            fontWeight: FontWeights.weight400,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.edit_outlined,
                        color: ui.textSecondary,
                        size: 22.r,
                      ),
                    ),
                    IconButton(
                      onPressed: () {},
                      icon: Icon(
                        Icons.delete_outline_rounded,
                        color: AppColors.removeColor,
                        size: 22.r,
                      ),
                    ),
                  ],
                ),
                10.verticalSpace,
                Container(
                  padding: EdgeInsets.fromLTRB(12.w, 10.h, 12.w, 10.h),
                  decoration: BoxDecoration(
                    color: t.mintIconBackground.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(10.r),
                    border: Border.all(
                      color: t.brandGreen.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              'Current Range',
                              color: t.textSecondary,
                              fontSize: FontSizes.font12Sp,
                              fontWeight: FontWeights.weight500,
                            ),
                          ),
                          AppText(
                            '${vehicle.rangeKm} km',
                            color: t.brandGreenLight,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight700,
                          ),
                        ],
                      ),
                      8.verticalSpace,
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: LinearProgressIndicator(
                          value: vehicle.rangeFraction,
                          minHeight: 6.h,
                          backgroundColor: t.progressTrack,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            t.brandGreen,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: _VehicleStatBox(
                        icon: Icons.battery_charging_full_rounded,
                        label: 'Capacity',
                        value: vehicle.capacityKwh,
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: _VehicleStatBox(
                        icon: Icons.trending_up_rounded,
                        label: 'Efficiency',
                        value: vehicle.efficiency,
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: _VehicleStatBox(
                        icon: Icons.bolt_rounded,
                        label: 'Charges',
                        value: vehicle.charges,
                      ),
                    ),
                  ],
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: AppText(
                        'Total Energy Charged',
                        color: ui.textSecondary,
                        fontSize: FontSizes.font12Sp,
                        fontWeight: FontWeights.weight400,
                      ),
                    ),
                    AppText(
                      vehicle.totalEnergyKwh,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ],
                ),
                if (!vehicle.isPrimary) ...[
                  14.verticalSpace,
                  PrimaryButtonWidget(
                    text: 'Set as Primary Vehicle',
                    onPress: () {},
                    buttonWidth: double.infinity,
                    buttonHeight: 44.h,
                    cornerRadius: 12.r,
                    buttonColor: ui.chipInactiveBg,
                    strokeColor: t.brandGreen,
                    textColor: t.brandGreenLight,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ],
                if (vehicle.chargingPatterns != null) ...[
                  16.verticalSpace,
                  _ChargingPatternsSection(
                    data: vehicle.chargingPatterns!,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _VehicleStatBox extends StatelessWidget {
  const _VehicleStatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: ui.vehicleStatBoxBg,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: t.stationCardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: t.brandGreen, size: 18.r),
          6.verticalSpace,
          AppText(
            label,
            color: ui.textSecondary,
            fontSize: FontSizes.font10Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
          4.verticalSpace,
          AppText(
            value,
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight700,
            textAlign: TextAlign.center,
            maxLines: 2,
          ),
        ],
      ),
    );
  }
}

class _ChargingPatternsSection extends StatelessWidget {
  const _ChargingPatternsSection({required this.data});

  final _ChargingPatternsUi data;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      width: double.infinity,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: t.pricingCardBackground.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: t.stationCardBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(
            title: 'Charging Patterns',
            icon: Icons.calendar_month_outlined,
            compact: true,
          ),
          12.verticalSpace,
          _PatternRow(label: 'Most Active Day', value: data.mostActiveDay),
          _DividerLine(),
          _PatternRow(label: 'Preferred Time', value: data.preferredTime),
          _DividerLine(),
          _PatternRow(label: 'Avg. Charge Duration', value: data.avgDuration),
          _DividerLine(),
          _PatternRow(label: 'Favorite Station', value: data.favoriteStation),
        ],
      ),
    );
  }
}

class _PatternRow extends StatelessWidget {
  const _PatternRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: AppText(
              label,
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          ),
          AppText(
            value,
            color: ui.textPrimary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight700,
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }
}

class _SettingsTabBody extends StatelessWidget {
  const _SettingsTabBody({required this.state});

  final ProfileLoaded state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ProfileCubit>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitleRow(
                title: 'Notifications',
                icon: Icons.notifications_outlined,
              ),
              8.verticalSpace,
              _NotificationRow(
                title: 'Charging Updates',
                subtitle: 'Get notified about charging status',
                value: state.notifyChargingUpdates,
                onChanged: cubit.setNotifyChargingUpdates,
              ),
              _DividerLine(),
              _NotificationRow(
                title: 'Booking Reminders',
                subtitle: 'Reminders for upcoming bookings',
                value: state.notifyBookingReminders,
                onChanged: cubit.setNotifyBookingReminders,
              ),
              _DividerLine(),
              _NotificationRow(
                title: 'Promotional Offers',
                subtitle: 'Special deals and discounts',
                value: state.notifyPromotionalOffers,
                onChanged: cubit.setNotifyPromotionalOffers,
              ),
              _DividerLine(),
              _NotificationRow(
                title: 'App Updates',
                subtitle: 'New features and improvements',
                value: state.notifyAppUpdates,
                onChanged: cubit.setNotifyAppUpdates,
              ),
            ],
          ),
        ),
        14.verticalSpace,
        const _AppearanceSection(),
        14.verticalSpace,
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionTitleRow(
                title: 'Account',
                icon: Icons.manage_accounts_outlined,
              ),
              10.verticalSpace,
              _AccountTile(
                icon: Icons.shield_outlined,
                label: 'Privacy & Security',
                onTap: () {},
              ),
              _DividerLine(),
              _AccountTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final ui = AppUiColors.of(context);
    final themeCubit = context.read<ThemeCubit>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitleRow(
            title: 'Appearance',
            icon: Icons.brightness_6_outlined,
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: PrimaryButtonWidget(
                  text: 'Light',
                  onPress: themeCubit.setLight,
                  buttonHeight: 44.h,
                  cornerRadius: 10.r,
                  buttonColor: isLight ? t.brandGreen : ui.chipInactiveBg,
                  strokeColor: t.brandGreen,
                  textColor: isLight ? t.textOnBrand : t.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ),
              10.horizontalSpace,
              Expanded(
                child: PrimaryButtonWidget(
                  text: 'Dark',
                  onPress: themeCubit.setDark,
                  buttonHeight: 44.h,
                  cornerRadius: 10.r,
                  buttonColor: !isLight ? t.brandGreen : ui.chipInactiveBg,
                  strokeColor: t.brandGreen,
                  textColor: !isLight ? t.textOnBrand : t.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
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
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
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
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.whiteColor,
            activeTrackColor: t.brandGreen,
            inactiveThumbColor: AppColors.iconsGreyColor,
            inactiveTrackColor: t.progressTrack,
          ),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
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
              Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: t.mintIconBackground.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(icon, color: t.brandGreen, size: 20.r),
              ),
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: t.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: t.stationCardBorder),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Section heading with mint icon badge — matches booking / payment screens.
class _SectionTitleRow extends StatelessWidget {
  const _SectionTitleRow({
    required this.title,
    required this.icon,
    this.compact = false,
  });

  final String title;
  final IconData icon;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    final titleSize =
        compact ? FontSizes.font14Sp : FontSizes.font16Sp;
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(compact ? 6.r : 8.r),
          decoration: BoxDecoration(
            color: t.mintIconBackground.withValues(alpha: 0.55),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: t.brandGreen,
            size: compact ? 18.r : 20.r,
          ),
        ),
        8.horizontalSpace,
        Expanded(
          child: AppText(
            title,
            color: t.textPrimary,
            fontSize: titleSize,
            fontWeight: FontWeights.weight700,
          ),
        ),
      ],
    );
  }
}

/// Primary CTA button with the app-wide green gradient and 24.r corners,
/// matching the buttons used across the booking / auth / trip screens.
class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.text,
    required this.onPressed,
    this.height,
    this.fontSize,
    this.fontWeight,
  });

  final String text;
  final VoidCallback onPressed;
  final double? height;
  final double? fontSize;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    final t = context.revampedTheme;
    return SizedBox(
      width: double.infinity,
      height: height ?? 52.h,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              t.bookSlotDarkGreen,
              t.bookSlotPrimaryGreen,
            ],
          ),
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: t.bookSlotPrimaryGreen.withValues(alpha: 0.28),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparentColor,
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(24.r),
            child: Center(
              child: AppText(
                text,
                color: t.textOnBrand,
                fontSize: fontSize ?? FontSizes.font15Sp,
                fontWeight: fontWeight ?? FontWeights.weight700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

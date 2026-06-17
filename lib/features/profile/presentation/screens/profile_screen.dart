import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/core/theme/theme_cubit.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/gradient_switch.dart';
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
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return Center(
                child: CircularProgressIndicator(
                  color: ui.brandPrimary,
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
                      color: AppColors.iconsGreyColor,
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
                    PrimaryButtonWidget(
                      text: 'Retry',
                      onPress: () =>
                          context.read<ProfileCubit>().loadProfile(),
                      buttonWidth: double.infinity,
                      buttonHeight: 38.h,
                      cornerRadius: 12.r,
                      buttonColor: ui.brandPrimary,
                      textColor: AppColors.whiteColor,
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
    final ui = AppUiColors.of(context);
    final cubit = context.read<ProfileCubit>();
    final profile = state.profile;
    final bottomRadius = 20.r;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        // gradient: const LinearGradient(
        //   begin: Alignment.topCenter,
        //   end: Alignment.bottomCenter,
        //   colors: [
        //     AppColors.transparentColor,
        //     AppColors.transparentColor,
        //   ],
        // ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(bottomRadius),
          bottomRight: Radius.circular(bottomRadius),
        ),
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
                    backgroundColor: ui.textSecondary,
                        // AppColors.whiteColor.withValues(alpha: 0.2),
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
                          color: ui.brandPrimary,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.photo_camera_outlined,
                        size: 14.r,
                        color: ui.brandPrimary,
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
                      color: ui.textPrimary,
                      fontSize: FontSizes.font20Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      profile.email,
                      color: ui.textSecondary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      'Member since Jan 2024',
                      color: ui.textSecondary,
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
    final ui = AppUiColors.of(context);
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 6.w),
          decoration: BoxDecoration(
            color: AppColors.transparentColor,
            borderRadius: BorderRadius.circular(20.r),
            border: Border.all(
              color: selected ? ui.brandPrimary : ui.textMuted,
              width: selected ? 2.w : 1.w
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.r,
                color:ui.textMuted,
              ),
              4.horizontalSpace,
              Flexible(
                child: AppText(
                  label,
                  color: ui.textPrimary,
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
        // _AchievementsCard(),
        // 14.verticalSpace,
        _PersonalInfoCard(profile: profile),
        14.verticalSpace,
        // _DrivingEfficiencyCard(),
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                icon: Icons.bolt_rounded,
                iconBg: AppColors.transparentColor,
                iconColor: ui.brandSecondary,
                value: '47',
                valueColor: ui.textPrimary,
                label: 'Total Charges',
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: _StatTile(
                icon: Icons.battery_charging_full_rounded,
                iconBg: AppColors.transparentColor,
                iconColor: ui.brandSecondary,
                value: '1245',
                valueColor: ui.textPrimary,
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
                icon: Icons.trending_up_rounded,
                iconBg: AppColors.transparentColor,
                iconColor: ui.brandSecondary,
                value: 'PKR 12,450',
                valueColor: ui.textPrimary,
                label: 'Money Saved',
              ),
            ),
            10.horizontalSpace,
            Expanded(
              child: _StatTile(
                icon: Icons.eco_outlined,
                iconBg: AppColors.transparentColor,
                iconColor: ui.brandSecondary,
                value: '285 kg',
                valueColor: ui.textPrimary,
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
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.vehicleImagePlaceholder,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
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
            color: ui.textSecondary,
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
    final ui = AppUiColors.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.workspace_premium_outlined,
                color: ui.brandLightGreen,
                size: 22.r,
              ),
              8.horizontalSpace,
              AppText(
                'Achievements',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _AchievementBadge(
                label: 'Early Adopter',
                icon: Icons.military_tech_rounded,
                circleColor: AppColors.slotBusyYellowColor.withValues(alpha: 0.35),
                iconColor: AppColors.ratingStarColor,
              ),
              _AchievementBadge(
                label: 'Eco Warrior',
                icon: Icons.trending_up_rounded,
                circleColor: ui.brandDarkGreen.withValues(alpha: 0.35),
                iconColor: ui.brandLightGreen,
              ),
              _AchievementBadge(
                label: 'Road Tripper',
                icon: Icons.directions_car_filled_rounded,
                circleColor: AppColors.mapPinBlueColor.withValues(alpha: 0.25),
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
          color: AppUiColors.of(context).textSecondary,
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
    final ui = AppUiColors.of(context);
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Personal Information',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font16Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
              PrimaryButtonWidget(
                text: 'Edit',
                onPress: () {},
                buttonWidth: 88.w,
                buttonHeight: 38.h,
                cornerRadius: 24.r,
                buttonColor: ui.editButtonColor,
                strokeColor: ui.borderSubtle,
                textColor: ui.textPrimary,
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
    final ui = AppUiColors.of(context);
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.drivingEfficiencyBg,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ui.drivingEfficiencyBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppText(
            'Driving Efficiency',
            color: ui.textPrimary,
            fontSize: FontSizes.font16Sp,
            fontWeight: FontWeights.weight700,
          ),
          14.verticalSpace,
          Row(
            children: [
              Expanded(
                child: AppText(
                  'Overall Efficiency',
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
              ),
              AppText(
                '92%',
                color: ui.brandPrimary,
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
              backgroundColor: ui.progressTrack,
              valueColor: AlwaysStoppedAnimation<Color>(ui.brandPrimary),
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
              color: ui.efficiencyTipBg,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: AppText(
              'Efficiency Tip: Maintain steady speeds on highways to improve range by up to 15%.',
              color: ui.brandPrimary,
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
    final ui = AppUiColors.of(context);
    return Container(
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        color: ui.innerCardBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText(
            title,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
          ),
          6.verticalSpace,
          AppText(
            value,
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
          ),
        ],
      ),
    );
  }
}

class _VehiclesTabBody extends StatefulWidget {
  const _VehiclesTabBody();

  @override
  State<_VehiclesTabBody> createState() => _VehiclesTabBodyState();
}

class _VehiclesTabBodyState extends State<_VehiclesTabBody> {
  static const _VehicleUi _seedVehicle = _VehicleUi(
    nickname: 'BYD Atto 3 - Primary Vehicle',
    modelLine: '2023 BYD Atto 3',
    make: 'BYD',
    model: 'Atto 3',
    year: '2023',
    isPrimary: true,
    rangeKm: 245,
    rangeFraction: 0.72,
    capacityKwh: '50 kWh',
    efficiency: '6.4 KM/kWh',
    charges: '47',
    totalEnergyKwh: '1245 kWh',
    imagePath: 'assets/images/byd_atto3.jpg',
    chargingPatterns: null,
  );

  final LocalStorageService _storage = sl<LocalStorageService>();

  late final List<_VehicleUi> _vehicles = _loadVehicles();

  List<_VehicleUi> _loadVehicles() {
    final initialized =
        _storage.read<bool>(StorageConstants.vehiclesInitialized) ?? false;
    if (!initialized) {
      _storage.write(StorageConstants.vehiclesInitialized, true);
      _storage.write(
        StorageConstants.vehicles,
        [_seedVehicle.toJson()],
      );
      return [_seedVehicle];
    }
    final raw = _storage.read<List<dynamic>>(StorageConstants.vehicles);
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((e) => _VehicleUi.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> _persistVehicles() {
    return _storage.write(
      StorageConstants.vehicles,
      _vehicles.map((v) => v.toJson()).toList(),
    );
  }

  Future<void> _addVehicle() async {
    final vehicle = await _showAddVehicleDialog(context);
    if (vehicle == null) return;
    setState(() => _vehicles.add(vehicle));
    await _persistVehicles();
  }

  Future<void> _editVehicle(int index) async {
    final updated =
        await _showAddVehicleDialog(context, initial: _vehicles[index]);
    if (updated == null) return;
    setState(() => _vehicles[index] = updated);
    await _persistVehicles();
  }

  Future<void> _deleteVehicle(int index) async {
    final confirmed = await _showDeleteVehicleDialog(
      context,
      _vehicles[index],
    );
    if (confirmed != true) return;
    setState(() => _vehicles.removeAt(index));
    await _persistVehicles();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PrimaryButtonWidget(
          text: 'Add New Vehicle',
          onPress: _addVehicle,
          buttonWidth: double.infinity,
          buttonHeight: 38.h,
          cornerRadius: 24.r,
          gradientColors: const [
            AppColors.primaryDarkColor,
            AppColors.primaryDarkButtonColor,
          ],
          textColor: AppColors.whiteColor,
          fontSize: FontSizes.font15Sp,
          fontWeight: FontWeights.weight700,
        ),
        14.verticalSpace,
        if (_vehicles.isEmpty)
          _EmptyVehiclesPlaceholder(ui: ui)
        else
          ...List.generate(
            _vehicles.length,
            (index) => Padding(
              padding: EdgeInsets.only(bottom: 14.h),
              child: _VehicleCard(
                vehicle: _vehicles[index],
                onEdit: () => _editVehicle(index),
                onDelete: () => _deleteVehicle(index),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyVehiclesPlaceholder extends StatelessWidget {
  const _EmptyVehiclesPlaceholder({required this.ui});

  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 32.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: ui.vehicleImagePlaceholder,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        children: [
          Icon(
            Icons.directions_car_outlined,
            size: 44.r,
            color: ui.textSecondary,
          ),
          12.verticalSpace,
          AppText(
            'No vehicles yet',
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
          ),
          6.verticalSpace,
          AppText(
            'Tap "Add New Vehicle" to add your first one.',
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

Future<_VehicleUi?> _showAddVehicleDialog(
  BuildContext context, {
  _VehicleUi? initial,
}) {
  return showDialog<_VehicleUi>(
    context: context,
    barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
    builder: (_) => _AddVehicleDialog(initial: initial),
  );
}

Future<bool?> _showDeleteVehicleDialog(
  BuildContext context,
  _VehicleUi vehicle,
) {
  final ui = AppUiColors.of(context);
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
    builder: (dialogContext) => Dialog(
      backgroundColor: ui.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Padding(
        padding: AppUtils.all18Padding,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.r),
                  decoration: BoxDecoration(
                    color: AppColors.removeColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.removeColor,
                    size: 22.r,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: AppText(
                    'Delete Vehicle',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font18Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
            14.verticalSpace,
            AppText(
              'Are you sure you want to delete "${vehicle.nickname}"? This action cannot be undone.',
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
              height: 1.4,
            ),
            22.verticalSpace,
            Row(
              children: [
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'Cancel',
                    onPress: () => Navigator.of(dialogContext).pop(false),
                    buttonWidth: double.infinity,
                    // buttonHeight: 42.h,
                    cornerRadius: 12.r,
                    buttonColor: ui.chipInactiveBg,
                    strokeColor: ui.borderSubtle,
                    textColor: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: PrimaryButtonWidget(
                    text: 'Delete',
                    onPress: () => Navigator.of(dialogContext).pop(true),
                    buttonWidth: double.infinity,
                    buttonHeight: 42.h,
                    cornerRadius: 12.r,
                    buttonColor: AppColors.removeColor,
                    textColor: AppColors.whiteColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _AddVehicleDialog extends StatefulWidget {
  const _AddVehicleDialog({this.initial});

  final _VehicleUi? initial;

  @override
  State<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

/// Electric & hybrid vehicle makes mapped to their popular models.
const Map<String, List<String>> _evMakeModels = {
  'Tesla': ['Model 3', 'Model Y', 'Model S', 'Model X', 'Cybertruck'],
  'BYD': ['Atto 3', 'Dolphin', 'Seal', 'Han', 'Tang'],
  'BMW': ['i4', 'iX', 'i7', 'iX3', '330e', 'X5 xDrive45e'],
  'Mercedes-Benz': ['EQA', 'EQB', 'EQC', 'EQE', 'EQS', 'C 300 e'],
  'Audi': ['e-tron GT', 'Q4 e-tron', 'Q8 e-tron', 'A6 e-tron'],
  'Nissan': ['Leaf', 'Ariya'],
  'Hyundai': ['Ioniq 5', 'Ioniq 6', 'Kona Electric'],
  'Kia': ['EV6', 'Niro EV', 'Niro Hybrid', 'Sorento Hybrid'],
  'Toyota': ['Prius', 'bZ4X', 'Corolla Hybrid', 'RAV4 Hybrid', 'Camry Hybrid'],
  'Volkswagen': ['ID.3', 'ID.4', 'ID.Buzz'],
  'MG': ['MG4 EV', 'MG ZS EV', 'MG HS PHEV'],
  'Porsche': ['Taycan', 'Cayenne E-Hybrid', 'Panamera E-Hybrid'],
  'Polestar': ['Polestar 2', 'Polestar 3', 'Polestar 4'],
  'Volvo': ['EX30', 'EX90', 'XC40 Recharge', 'XC60 Recharge'],
  'Honda': ['e:Ny1', 'CR-V Hybrid', 'Accord Hybrid'],
};

class _AddVehicleDialogState extends State<_AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();

  String? _selectedMake;
  String? _selectedModel;

  bool get _isEditing => widget.initial != null;

  List<String> get _availableModels =>
      _selectedMake == null ? const [] : (_evMakeModels[_selectedMake] ?? const []);

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    if (initial == null) return;

    if (initial.make != null && _evMakeModels.containsKey(initial.make)) {
      _selectedMake = initial.make;
      if (initial.model != null &&
          _evMakeModels[initial.make]!.contains(initial.model)) {
        _selectedModel = initial.model;
      }
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final make = _selectedMake!;
    final model = _selectedModel!;

    final base = widget.initial;
    final result = (base ??
            const _VehicleUi(
              nickname: '',
              modelLine: '',
              isPrimary: false,
              rangeKm: 0,
              rangeFraction: 0,
              capacityKwh: 'N/A',
              efficiency: 'N/A',
              charges: '0',
              totalEnergyKwh: '0 kWh',
            ))
        .copyWith(
      nickname: '$make $model',
      modelLine: '$make $model',
      make: make,
      model: model,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Dialog(
      backgroundColor: ui.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Padding(
        padding: AppUtils.all18Padding,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: ui.brandPrimary.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.directions_car_outlined,
                        color: ui.brandPrimary,
                        size: 22.r,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: AppText(
                        _isEditing ? 'Edit Vehicle' : 'Add New Vehicle',
                        color: ui.textPrimary,
                        fontSize: FontSizes.font18Sp,
                        fontWeight: FontWeights.weight700,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      behavior: HitTestBehavior.opaque,
                      child: Icon(
                        Icons.close_rounded,
                        color: ui.textSecondary,
                        size: 22.r,
                      ),
                    ),
                  ],
                ),
                6.verticalSpace,
                AppText(
                  _isEditing
                      ? 'Update your vehicle details below.'
                      : 'Enter your vehicle details below.',
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                ),
                18.verticalSpace,
                _AddVehicleDropdownField(
                  ui: ui,
                  label: 'Make',
                  hintText: 'Select make',
                  value: _selectedMake,
                  items: _evMakeModels.keys.toList(),
                  validator: (value) =>
                      value == null ? 'Make is required' : null,
                  onChanged: (value) {
                    setState(() {
                      _selectedMake = value;
                      _selectedModel = null;
                    });
                  },
                ),
                14.verticalSpace,
                _AddVehicleDropdownField(
                  ui: ui,
                  label: 'Model',
                  hintText: _selectedMake == null
                      ? 'Select make first'
                      : 'Select model',
                  value: _selectedModel,
                  items: _availableModels,
                  enabled: _selectedMake != null,
                  validator: (value) =>
                      value == null ? 'Model is required' : null,
                  onChanged: (value) {
                    setState(() => _selectedModel = value);
                  },
                ),
                22.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: PrimaryButtonWidget(
                        text: 'Cancel',
                        onPress: () => Navigator.of(context).pop(),
                        buttonWidth: double.infinity,
                        buttonHeight: 42.h,
                        cornerRadius: 12.r,
                        buttonColor: ui.chipInactiveBg,
                        strokeColor: ui.borderSubtle,
                        textColor: ui.textPrimary,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight600,
                      ),
                    ),
                    12.horizontalSpace,
                    Expanded(
                      child: PrimaryButtonWidget(
                        text: _isEditing ? 'Save' : 'Add Vehicle',
                        onPress: _submit,
                        buttonWidth: double.infinity,
                        buttonHeight: 42.h,
                        cornerRadius: 12.r,
                        buttonColor: ui.brandPrimary,
                        textColor: AppColors.whiteColor,
                        fontSize: FontSizes.font14Sp,
                        fontWeight: FontWeights.weight700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AddVehicleDropdownField extends StatelessWidget {
  const _AddVehicleDropdownField({
    required this.ui,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.enabled = true,
  });

  final AppUiColors ui;
  final String label;
  final String hintText;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? Function(String?)? validator;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          label,
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        DropdownButtonFormField<String>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: enabled ? ui.textSecondary : ui.textMuted,
            size: 22.r,
          ),
          dropdownColor: ui.cardBackground,
          borderRadius: BorderRadius.circular(12.r),
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            fontFamily: AppFonts.lexend,
          ),
          hint: AppText(
            hintText,
            color: AppColors.hintColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
          ),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: AppText(
                    item,
                    color: ui.textPrimary,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight500,
                  ),
                ),
              )
              .toList(),
          decoration: InputDecoration(
            filled: true,
            fillColor: ui.inputFill,
            isDense: true,
            contentPadding:
                EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.brandPrimary),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: BorderSide(color: ui.inputBorder),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.r),
              borderSide: const BorderSide(color: AppColors.redColor),
            ),
            errorStyle: TextStyle(
              color: AppColors.redColor,
              fontSize: FontSizes.font10Sp,
              fontWeight: FontWeights.weight400,
            ),
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

  Map<String, dynamic> toJson() => {
        'mostActiveDay': mostActiveDay,
        'preferredTime': preferredTime,
        'avgDuration': avgDuration,
        'favoriteStation': favoriteStation,
      };

  factory _ChargingPatternsUi.fromJson(Map<String, dynamic> json) {
    return _ChargingPatternsUi(
      mostActiveDay: json['mostActiveDay'] as String? ?? '',
      preferredTime: json['preferredTime'] as String? ?? '',
      avgDuration: json['avgDuration'] as String? ?? '',
      favoriteStation: json['favoriteStation'] as String? ?? '',
    );
  }
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
    this.make,
    this.model,
    this.year,
    this.registration,
    this.imagePath,
    this.chargingPatterns,
  });

  final String nickname;
  final String modelLine;
  final String? make;
  final String? model;
  final String? year;
  final String? registration;
  final bool isPrimary;
  final int rangeKm;
  final double rangeFraction;
  final String capacityKwh;
  final String efficiency;
  final String charges;
  final String totalEnergyKwh;
  final String? imagePath;
  final _ChargingPatternsUi? chargingPatterns;

  _VehicleUi copyWith({
    String? nickname,
    String? modelLine,
    String? make,
    String? model,
    String? year,
    String? registration,
    bool? isPrimary,
  }) {
    return _VehicleUi(
      nickname: nickname ?? this.nickname,
      modelLine: modelLine ?? this.modelLine,
      make: make ?? this.make,
      model: model ?? this.model,
      year: year ?? this.year,
      registration: registration ?? this.registration,
      isPrimary: isPrimary ?? this.isPrimary,
      rangeKm: rangeKm,
      rangeFraction: rangeFraction,
      capacityKwh: capacityKwh,
      efficiency: efficiency,
      charges: charges,
      totalEnergyKwh: totalEnergyKwh,
      imagePath: imagePath,
      chargingPatterns: chargingPatterns,
    );
  }

  Map<String, dynamic> toJson() => {
        'nickname': nickname,
        'modelLine': modelLine,
        'make': make,
        'model': model,
        'year': year,
        'registration': registration,
        'isPrimary': isPrimary,
        'rangeKm': rangeKm,
        'rangeFraction': rangeFraction,
        'capacityKwh': capacityKwh,
        'efficiency': efficiency,
        'charges': charges,
        'totalEnergyKwh': totalEnergyKwh,
        'imagePath': imagePath,
        'chargingPatterns': chargingPatterns?.toJson(),
      };

  factory _VehicleUi.fromJson(Map<String, dynamic> json) {
    final patterns = json['chargingPatterns'];
    return _VehicleUi(
      nickname: json['nickname'] as String? ?? '',
      modelLine: json['modelLine'] as String? ?? '',
      make: json['make'] as String?,
      model: json['model'] as String?,
      year: json['year'] as String?,
      registration: json['registration'] as String?,
      isPrimary: json['isPrimary'] as bool? ?? false,
      rangeKm: (json['rangeKm'] as num?)?.toInt() ?? 0,
      rangeFraction: (json['rangeFraction'] as num?)?.toDouble() ?? 0,
      capacityKwh: json['capacityKwh'] as String? ?? 'N/A',
      efficiency: json['efficiency'] as String? ?? 'N/A',
      charges: json['charges'] as String? ?? '0',
      totalEnergyKwh: json['totalEnergyKwh'] as String? ?? '0 kWh',
      imagePath: json['imagePath'] as String?,
      chargingPatterns: patterns is Map
          ? _ChargingPatternsUi.fromJson(Map<String, dynamic>.from(patterns))
          : null,
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    this.onEdit,
    this.onDelete,
  });

  final _VehicleUi vehicle;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  Widget _vehicleImagePlaceholder(AppUiColors ui) {
    return Container(
      height: 140.h,
      width: double.infinity,
      color: ui.vehicleImagePlaceholder,
      alignment: Alignment.center,
      child: Icon(
        Icons.electric_car_rounded,
        size: 72.r,
        color: ui.brandPrimary.withValues(alpha: 0.85),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: ui.brandPrimary.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              if (vehicle.imagePath != null)
                Image.asset(
                  vehicle.imagePath!,
                  height: 140.h,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _vehicleImagePlaceholder(ui),
                )
              else
                _vehicleImagePlaceholder(ui),
              // if (vehicle.isPrimary)
              //   Positioned(
              //     top: 10.h,
              //     right: 10.w,
              //     child: Container(
              //       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              //       decoration: BoxDecoration(
              //         color: ui.brandPrimary,
              //         borderRadius: BorderRadius.circular(8.r),
              //       ),
              //       child: AppText(
              //         'Primary Vehicle',
              //         color: AppColors.whiteColor,
              //         fontSize: FontSizes.font10Sp,
              //         fontWeight: FontWeights.weight600,
              //       ),
              //     ),
              //   ),
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
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight700,
                          ),
                          4.verticalSpace,
                          AppText(
                            vehicle.modelLine,
                            color: ui.textSecondary,
                            fontSize: FontSizes.font12Sp,
                            fontWeight: FontWeights.weight400,
                          ),
                          if (vehicle.registration != null &&
                              vehicle.registration!.isNotEmpty) ...[
                            6.verticalSpace,
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 8.w, vertical: 3.h),
                              decoration: BoxDecoration(
                                color: ui.brandPrimary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6.r),
                              ),
                              child: AppText(
                                vehicle.registration!,
                                color: ui.brandPrimary,
                                fontSize: FontSizes.font10Sp,
                                fontWeight: FontWeights.weight600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: onEdit,
                      icon: Icon(
                        Icons.edit_outlined,
                        color: ui.textSecondary,
                        size: 22.r,
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
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
                    color: AppColors.transparentColor,
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: AppText(
                              'Current Range',
                              color: ui.textPrimary.withValues(alpha: 0.85),
                              fontSize: FontSizes.font12Sp,
                              fontWeight: FontWeights.weight500,
                            ),
                          ),
                          AppText(
                            '${vehicle.rangeKm} km',
                            color: ui.textMuted,
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
                          backgroundColor: ui.progressTrack,
                          valueColor: AlwaysStoppedAnimation<Color>(ui.brandPrimary),
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
                    buttonHeight: 38.h,
                    cornerRadius: 12.r,
                    buttonColor: ui.chipInactiveBg,
                    strokeColor: ui.brandPrimary,
                    textColor: ui.textMuted,
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
    final ui = AppUiColors.of(context);
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
      decoration: BoxDecoration(
        color: ui.vehicleStatBoxBg,
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Column(
        children: [
          Icon(icon, color: ui.textSecondary, size: 18.r),
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
    final ui = AppUiColors.of(context);
    return Container(
      width: double.infinity,
      padding: AppUtils.all12Padding,
      decoration: BoxDecoration(
        // color: ui.chargingPatternsBg,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: ui.chargingPatternsBorder,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: ui.textPrimary,
                size: 20.r,
              ),
              8.horizontalSpace,
              AppText(
                'Charging Patterns',
                color: ui.textPrimary,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
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
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: ui.textMuted,
                    size: 20.r,
                  ),
                  8.horizontalSpace,
                  AppText(
                    'Notifications',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font16Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ],
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
              AppText(
                'Account',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
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
    final ui = AppUiColors.of(context);
    final themeCubit = context.read<ThemeCubit>();
    final isLight = Theme.of(context).brightness == Brightness.light;

    return _SectionCard(
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
                  // buttonColor: !isLight ? AppColors.whiteColor.withValues(alpha: 0.16) : null,
                  gradientColors: !isLight ? [
                    AppColors.primaryDarkColor,
                    AppColors.primaryDarkButtonColor,
                  ] : null,
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
                  buttonColor: isLight ? AppColors.whiteColor.withValues(alpha: 0.12) : null,
                  gradientColors: !isLight ? [
                    AppColors.primaryDarkColor,
                    AppColors.primaryDarkButtonColor,
                  ] : null,
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

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({
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

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.vehicleImagePlaceholder,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: ui.borderSubtle,
        ),
      ),
      child: child,
    );
  }
}

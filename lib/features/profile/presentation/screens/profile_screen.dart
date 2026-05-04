import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';

/// Account profile tab — dark UI aligned with charging / map screens.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ProfileCubit>().loadProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.blackColor,
      body: SafeArea(
        child: BlocBuilder<ProfileCubit, ProfileState>(
          builder: (context, state) {
            if (state is ProfileLoading || state is ProfileInitial) {
              return Center(
                child: CircularProgressIndicator(
                  color: AppColors.primaryDarkColor,
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
                      color: AppColors.whiteColor.withValues(alpha: 0.85),
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
                      buttonHeight: 48.h,
                      cornerRadius: 12.r,
                      buttonColor: AppColors.primaryDarkColor,
                      textColor: AppColors.whiteColor,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight600,
                    ),
                  ],
                ),
              );
            }

            if (state is ProfileLoaded) {
              return SingleChildScrollView(
                padding: AppUtils.horizontal16Padding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    8.verticalSpace,
                    AppText(
                      'Profile',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font26Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    20.verticalSpace,
                    _avatarCard(state.profile),
                    20.verticalSpace,
                    AppText(
                      'Account',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    10.verticalSpace,
                    _infoCard(state.profile),
                    20.verticalSpace,
                    AppText(
                      'More',
                      color: AppColors.whiteColor,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    10.verticalSpace,
                    _menuTile(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () {},
                    ),
                    8.verticalSpace,
                    _menuTile(
                      icon: Icons.payment_rounded,
                      label: 'Payment methods',
                      onTap: () {},
                    ),
                    8.verticalSpace,
                    _menuTile(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & support',
                      onTap: () {},
                    ),
                    24.verticalSpace,
                    PrimaryButtonWidget(
                      text: 'Edit profile',
                      onPress: () {},
                      buttonWidth: double.infinity,
                      buttonHeight: 50.h,
                      cornerRadius: 12.r,
                      buttonColor: AppColors.primaryDarkColor,
                      textColor: AppColors.whiteColor,
                      fontSize: FontSizes.font15Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                    12.verticalSpace,
                    Center(
                      child: TextButton(
                        onPressed: () {},
                        child: AppText(
                          'Sign out',
                          color: AppColors.removeColor,
                          fontSize: FontSizes.font14Sp,
                          fontWeight: FontWeights.weight600,
                        ),
                      ),
                    ),
                    24.verticalSpace,
                  ],
                ),
              );
            }

            return Center(
              child: AppText(
                'Welcome',
                color: AppColors.whiteColor,
                fontSize: FontSizes.font14Sp,
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _avatarCard(ProfileEntity profile) {
    return Container(
      width: double.infinity,
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.08),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36.r,
            backgroundColor: AppColors.greyColor.withValues(alpha: 0.35),
            backgroundImage: profile.avatarUrl != null
                ? NetworkImage(profile.avatarUrl!)
                : null,
            child: profile.avatarUrl == null
                ? AppText(
                    profile.name.isNotEmpty
                        ? profile.name[0].toUpperCase()
                        : '?',
                    color: AppColors.whiteColor,
                    fontSize: FontSizes.font28Sp,
                    fontWeight: FontWeights.weight700,
                  )
                : null,
          ),
          16.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  profile.name,
                  color: AppColors.whiteColor,
                  fontSize: FontSizes.font18Sp,
                  fontWeight: FontWeights.weight700,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                4.verticalSpace,
                AppText(
                  profile.email,
                  color: AppColors.iconsGreyColor,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(ProfileEntity profile) {
    final children = <Widget>[
      _infoRow(Icons.email_outlined, 'Email', profile.email),
    ];
    if (profile.phone != null) {
      children.addAll([
        Divider(
          height: 1,
          indent: 16.w,
          endIndent: 16.w,
          color: AppColors.whiteColor.withValues(alpha: 0.06),
        ),
        _infoRow(Icons.phone_outlined, 'Phone', profile.phone!),
      ]);
    }
    if (profile.bio != null) {
      children.addAll([
        Divider(
          height: 1,
          indent: 16.w,
          endIndent: 16.w,
          color: AppColors.whiteColor.withValues(alpha: 0.06),
        ),
        _infoRow(Icons.notes_outlined, 'Bio', profile.bio!, multiline: true),
      ]);
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.fieldBackgroundColor,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: AppColors.whiteColor.withValues(alpha: 0.08),
        ),
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(
    IconData icon,
    String label,
    String value, {
    bool multiline = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(
        crossAxisAlignment:
            multiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryDarkColor, size: 22.r),
          12.horizontalSpace,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText(
                  label,
                  color: AppColors.iconsGreyColor,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight500,
                ),
                4.verticalSpace,
                AppText(
                  value,
                  color: AppColors.whiteColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight500,
                  maxLines: multiline ? 6 : 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColors.transparentColor,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: AppColors.fieldBackgroundColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: AppColors.whiteColor.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColors.whiteColor.withValues(alpha: 0.85), size: 22.r),
              12.horizontalSpace,
              Expanded(
                child: AppText(
                  label,
                  color: AppColors.whiteColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight500,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.iconsGreyColor,
                size: 22.r,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

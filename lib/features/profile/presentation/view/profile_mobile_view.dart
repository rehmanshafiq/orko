import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/delete_account_button.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/logout_button.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/profile_header.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/profile_tab_body.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/settings_tab_body.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/vehicles_tab_body.dart';

/// Account profile hub: header with tabs, profile / vehicles / settings bodies.
class ProfileMobileView extends StatelessWidget {
  const ProfileMobileView({super.key});

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
              return _ProfileErrorView(message: state.message);
            }

            if (state is ProfileLoaded) {
              return _ProfileLoadedView(state: state);
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

/// Loaded state: sticky header + the scrollable body of the selected tab.
class _ProfileLoadedView extends StatelessWidget {
  const _ProfileLoadedView({required this.state});

  final ProfileLoaded state;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProfileHeader(state: state),
        Expanded(
          child: SingleChildScrollView(
            padding: AppUtils.horizontal16Padding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                16.verticalSpace,
                if (state.mainTab == ProfileMainTab.profile)
                  ProfileTabBody(profile: state.profile),
                if (state.mainTab == ProfileMainTab.vehicles)
                  const VehiclesTabBody(),
                if (state.mainTab == ProfileMainTab.settings) ...[
                  const SettingsTabBody(),
                  24.verticalSpace,
                  const LogoutButton(),
                  const DeleteAccountButton(),
                ],
                16.verticalSpace,
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Error state: message + retry.
class _ProfileErrorView extends StatelessWidget {
  const _ProfileErrorView({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
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
            message,
            color: ui.textPrimary.withValues(alpha: 0.85),
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight400,
            textAlign: TextAlign.center,
          ),
          24.verticalSpace,
          PrimaryButtonWidget(
            text: 'Retry',
            onPress: () => context.read<ProfileCubit>().loadProfile(),
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
}

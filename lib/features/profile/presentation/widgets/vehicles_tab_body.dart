import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/domain/usecases/get_user_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/utils/profile_actions.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/add_vehicle_dialog.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/profile_confirm_dialog.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/vehicle_card.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_cubit.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_state.dart';

/// Body of the "Vehicles" main tab: add-vehicle button plus the user's
/// vehicle list with loading / failure / empty states.
class VehiclesTabBody extends StatefulWidget {
  const VehiclesTabBody({super.key});

  @override
  State<VehiclesTabBody> createState() => _VehiclesTabBodyState();
}

class _VehiclesTabBodyState extends State<VehiclesTabBody> {
  @override
  void initState() {
    super.initState();
    // Load the user's vehicles the first time the tab is shown.
    final cubit = context.read<VehicleCubit>();
    if (cubit.state.vehiclesStatus == VehicleStatus.initial) {
      cubit.loadUserVehicles();
    }
  }

  Future<void> _addVehicle() async {
    // Guests can't own vehicles — prompt them to log in / sign up.
    if (AppStorage.isGuest) {
      AuthRequiredDialog.show(
        context,
        feature: 'vehicle',
        message: 'You\'re browsing as a guest. Please log in or create an '
            'account to add a vehicle.',
      );
      return;
    }

    final cubit = context.read<VehicleCubit>();
    final added = await showDialog<bool>(
      context: context,
      barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const AddVehicleDialog(),
      ),
    );
    // The list refreshes itself via the cubit; no confirmation toast.
    // A new vehicle changes the user object, so refresh the cached user.
    if (added == true && mounted) {
      unawaited(_refreshCachedUser());
    }
  }

  /// Re-fetches the user (`getUser`) so the cached user reflects the new
  /// vehicle, then updates the global [UserBloc]. Best-effort and silent.
  Future<void> _refreshCachedUser() async {
    if (AppStorage.isGuest) return;
    final result = await sl<GetUserUseCase>()(const NoParams());
    if (!mounted) return;
    result.fold((_) {}, (_) {
      try {
        context.read<UserBloc>().add(const OnLoadCustomerFromCache());
      } catch (_) {
        // UserBloc not in scope here — the cache was still refreshed.
      }
    });
  }

  Future<void> _deleteVehicle(UserVehicleEntity vehicle) async {
    final cubit = context.read<VehicleCubit>();
    // Confirms the destructive delete before calling the API.
    final confirmed = await showProfileConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.removeColor,
      title: 'Delete Vehicle',
      message: 'Are you sure you want to delete "${vehicle.displayName}"? '
          'This action cannot be undone.',
      confirmText: 'Delete',
      buttonHeight: 38.h,
      buttonRadius: 24.r,
    );
    if (confirmed != true || !mounted) return;

    final result = await cubit.deleteVehicle(vehicle.id);
    if (!mounted) return;

    if (result.success) {
      // Removing a vehicle changes the user object — refresh the cached user.
      unawaited(_refreshCachedUser());
      return;
    }

    // Surface failures (e.g. "Vehicle not found.").
    showErrorSnackBar(context, result.message);
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, state) {
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
            _VehiclesBody(state: state, onDelete: _deleteVehicle),
          ],
        );
      },
    );
  }
}

/// The status-dependent part of the vehicles tab: spinner, failure + retry,
/// empty placeholder, or the vehicle list.
class _VehiclesBody extends StatelessWidget {
  const _VehiclesBody({required this.state, required this.onDelete});

  final VehicleState state;
  final ValueChanged<UserVehicleEntity> onDelete;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    switch (state.vehiclesStatus) {
      case VehicleStatus.initial:
      case VehicleStatus.loading:
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 40.h),
          child: Center(
            child: SizedBox(
              width: 28.w,
              height: 28.w,
              child: CircularProgressIndicator(
                strokeWidth: 2.6,
                color: ui.brandPrimary,
              ),
            ),
          ),
        );
      case VehicleStatus.failure:
        return Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(vertical: 28.h, horizontal: 16.w),
          decoration: BoxDecoration(
            color: ui.vehicleImagePlaceholder,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: ui.borderSubtle),
          ),
          child: Column(
            children: [
              Icon(Icons.cloud_off_outlined,
                  color: ui.textSecondary, size: 40.r),
              12.verticalSpace,
              AppText(
                state.vehiclesError ?? 'Could not load your vehicles.',
                color: ui.textSecondary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight400,
                textAlign: TextAlign.center,
              ),
              16.verticalSpace,
              SizedBox(
                width: 160.w,
                child: PrimaryButtonWidget(
                  text: 'Retry',
                  onPress: () =>
                      context.read<VehicleCubit>().loadUserVehicles(),
                  buttonHeight: 40.h,
                  cornerRadius: 22.r,
                  buttonColor: ui.brandPrimary,
                  textColor: AppColors.whiteColor,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
            ],
          ),
        );
      case VehicleStatus.success:
        if (state.vehicles.isEmpty) {
          return _EmptyVehiclesPlaceholder(ui: ui);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(
            state.vehicles.length,
            (index) {
              final vehicle = state.vehicles[index];
              return Padding(
                padding: EdgeInsets.only(bottom: 14.h),
                child: VehicleCard(
                  vehicle: vehicle,
                  isDeleting: state.isDeleting(vehicle.id),
                  onDelete: () => onDelete(vehicle),
                ),
              );
            },
          ),
        );
    }
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

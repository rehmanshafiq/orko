import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/profile/presentation/utils/profile_actions.dart';

/// "Logout" action at the bottom of the Settings tab. Shows a spinner while
/// the logout API call is in flight.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final isLoggingOut = authState is AuthLoading;
          return TextButton(
            onPressed: isLoggingOut ? null : () => handleSignOut(context),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: isLoggingOut
                ? SizedBox(
                    height: 18.r,
                    width: 18.r,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.removeColor,
                    ),
                  )
                : AppText(
                    'Logout',
                    color: AppColors.removeColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight600,
                  ),
          );
        },
      ),
    );
  }
}

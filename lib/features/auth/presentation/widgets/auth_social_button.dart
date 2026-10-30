import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/analytics_service.dart';
import 'package:orko_hubco/core/services/analytics_user_properties.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/image_view/app_image_view.dart';

/// Outlined pill button used for the social sign-in and guest options on the
/// auth screens.
class AuthSocialButton extends StatelessWidget {
  final IconData? icon;
  final String? imagePath;
  final String text;
  final VoidCallback onTap;
  final bool isLoading;
  final bool enabled;

  const AuthSocialButton({
    super.key,
    this.icon,
    this.imagePath,
    required this.text,
    required this.onTap,
    this.isLoading = false,
    this.enabled = true,
  }) : assert(icon != null || imagePath != null, 'Provide icon or imagePath');

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final Widget leadingIcon = isLoading
        ? SizedBox(
            height: 19.r,
            width: 19.r,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: ui.brandPrimary,
            ),
          )
        : imagePath != null
            ? AppPngImageView(
                appImagePath: imagePath!,
                height: 26.h,
                width: 26.w,
              )
            : Icon(icon, size: 19.r);

    return OutlinedButton.icon(
      onPressed: enabled ? onTap : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: ui.textPrimary,
        side: BorderSide(color: ui.inputBorder),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      ),
      icon: leadingIcon,
      label: AppText(
        text,
        color: ui.textPrimary,
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight500,
      ),
    );
  }
}

/// "Guest" button: enters the app as a guest. Guests can browse but not book;
/// the guest flag is cleared automatically once they log in or sign up.
class GuestButton extends StatelessWidget {
  final bool enabled;

  const GuestButton({super.key, this.enabled = true});

  Future<void> _onContinueAsGuest(BuildContext context) async {
    await AppStorage.setGuest(true);
    sl<AnalyticsService>().logEvent('guest_mode_entered');
    sl<AnalyticsUserProperties>().setGuest();
    if (!context.mounted) return;
    context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    return AuthSocialButton(
      icon: Icons.person_outline,
      text: 'Guest',
      enabled: enabled,
      onTap: () => _onContinueAsGuest(context),
    );
  }
}

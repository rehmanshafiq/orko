import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/core/services/push_notification_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/utils/profile_actions.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/profile_confirm_dialog.dart';

/// "Delete Account" action in the Settings tab. Hidden for guests (no account
/// to delete). Confirms first, then calls `delete-account`; on success the
/// session is cleared and the user is returned to login.
class DeleteAccountButton extends StatefulWidget {
  const DeleteAccountButton({super.key});

  @override
  State<DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<DeleteAccountButton> {
  bool _deleting = false;

  Future<void> _onDeleteAccount() async {
    final storage = sl<LocalStorageService>();
    if (storage.isGuest) return; // No server account for guests.

    final confirmed = await showProfileConfirmDialog(
      context,
      icon: Icons.delete_forever_rounded,
      iconColor: AppColors.removeColor,
      title: 'Delete Account',
      message:
          'Are you sure you want to delete your account? This permanently '
          'removes your account and all associated data. This action cannot '
          'be undone.',
      confirmText: 'Delete',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);

    // Best-effort: drop the device token server-side while the session is still
    // valid. Never blocks the deletion.
    try {
      await sl<PushNotificationService>().unregisterTokenFromBackend();
    } catch (_) {}

    final result = await sl<DeleteAccountUseCase>()(const NoParams());
    if (!mounted) return;

    await result.fold(
      (failure) async {
        setState(() => _deleting = false);
        showErrorSnackBar(context, failure.message);
      },
      (message) async {
        // The repository already cleared the cached session; clear remaining
        // user-specific local data and return to login.
        await clearUserData(storage);
        await storage.setGuest(false);
        if (!mounted) return;
        final messenger = ScaffoldMessenger.of(context);
        context.go('/login');
        messenger
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: AppColors.primaryDarkColor,
            ),
          );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Guests have no account to delete.
    if (sl<LocalStorageService>().isGuest) return const SizedBox.shrink();

    return Center(
      child: _deleting
          ? Padding(
              padding: EdgeInsets.symmetric(vertical: 10.h),
              child: SizedBox(
                height: 18.r,
                width: 18.r,
                child: const CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.removeColor,
                ),
              ),
            )
          : TextButton.icon(
              onPressed: _onDeleteAccount,
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 10.h),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              icon: Icon(
                Icons.delete_outline_rounded,
                color: AppColors.removeColor,
                size: 18.r,
              ),
              label: AppText(
                'Delete Account',
                color: AppColors.removeColor,
                fontSize: FontSizes.font14Sp,
                fontWeight: FontWeights.weight600,
              ),
            ),
    );
  }
}

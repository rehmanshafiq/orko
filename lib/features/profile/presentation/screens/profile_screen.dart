import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/core/services/push_notification_service.dart';
import 'package:orko_hubco/core/theme/theme_cubit.dart';
import 'package:orko_hubco/core/utils/image_upload_helper.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/features/auth/domain/usecases/delete_account_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/get_user_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/upload_user_picture_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/delete_user_picture_usecase.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/core/utils/widgets/gradient_switch.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/notifications/domain/entities/notification_preferences_entity.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notification_preferences_cubit.dart';
import 'package:orko_hubco/features/notifications/presentation/cubit/notification_preferences_state.dart';
import 'package:orko_hubco/features/profile/domain/entities/profile_entity.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_state.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';
import 'package:orko_hubco/features/profile/presentation/screens/edit_profile_screen.dart';
import 'package:orko_hubco/features/vehicle/domain/entities/user_vehicle_entity.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_cubit.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_state.dart';

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
                          if (state.mainTab == ProfileMainTab.settings) ...[
                            const _SettingsTabBody(),
                            24.verticalSpace,
                            Center(
                              child: BlocBuilder<AuthCubit, AuthState>(
                                builder: (context, authState) {
                                  final isLoggingOut = authState is AuthLoading;
                                  return TextButton(
                                    onPressed: isLoggingOut
                                        ? null
                                        : () => _onSignOut(context),
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
                                            'Sign out',
                                            color: AppColors.removeColor,
                                            fontSize: FontSizes.font14Sp,
                                            fontWeight: FontWeights.weight600,
                                          ),
                                  );
                                },
                              ),
                            ),
                            const _DeleteAccountButton(),
                          ],
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

/// Handles the Sign out action.
///
/// For guests there is no server session, so the logout API is skipped — we
/// just clear local user data and return to login. For authenticated users we
/// call the logout API first and only clear/navigate on success; a failure
/// surfaces a snackbar and leaves the user signed in.
Future<void> _onSignOut(BuildContext context) async {
  final storage = sl<LocalStorageService>();

  if (storage.isGuest) {
    await storage.setGuest(false);
    await _clearUserData(storage);
    if (context.mounted) context.go('/login');
    return;
  }

  final authCubit = context.read<AuthCubit>();
  await authCubit.logout();
  if (!context.mounted) return;

  if (authCubit.state is AuthError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text((authCubit.state as AuthError).message),
        backgroundColor: AppColors.removeColor,
      ),
    );
    return;
  }

  // API succeeded — clear user-specific data and navigate. App-level settings
  // (theme, onboarding, language) are left intact.
  await _clearUserData(storage);
  if (context.mounted) context.go('/login');
}

/// Removes this user's vehicle data while keeping app-level settings intact.
Future<void> _clearUserData(LocalStorageService storage) async {
  await storage.remove(StorageConstants.vehicles);
  await storage.remove(StorageConstants.vehiclesInitialized);
}

/// "Delete Account" action in the Settings tab. Hidden for guests (no account
/// to delete). Confirms first, then calls `delete-account`; on success the
/// session is cleared and the user is returned to login.
class _DeleteAccountButton extends StatefulWidget {
  const _DeleteAccountButton();

  @override
  State<_DeleteAccountButton> createState() => _DeleteAccountButtonState();
}

class _DeleteAccountButtonState extends State<_DeleteAccountButton> {
  bool _deleting = false;

  Future<void> _onDeleteAccount() async {
    final storage = sl<LocalStorageService>();
    if (storage.isGuest) return; // No server account for guests.

    final confirmed = await _showDeleteAccountDialog(context);
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
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(failure.message),
              backgroundColor: AppColors.removeColor,
            ),
          );
      },
      (message) async {
        // The repository already cleared the cached session; clear remaining
        // user-specific local data and return to login.
        await _clearUserData(storage);
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

/// Confirms permanent account deletion. Returns `true` when the user confirms.
Future<bool?> _showDeleteAccountDialog(BuildContext context) {
  final ui = AppUiColors.of(context);
  return showDialog<bool>(
    context: context,
    barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
    builder: (dialogContext) => Dialog(
      backgroundColor: ui.cardBackground,
      insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
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
                    Icons.delete_forever_rounded,
                    color: AppColors.removeColor,
                    size: 22.r,
                  ),
                ),
                12.horizontalSpace,
                Expanded(
                  child: AppText(
                    'Delete Account',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font18Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
              ],
            ),
            14.verticalSpace,
            AppText(
              'Are you sure you want to delete your account? This permanently '
              'removes your account and all associated data. This action cannot '
              'be undone.',
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
                    text: 'Delete',
                    onPress: () => Navigator.of(dialogContext).pop(true),
                    buttonWidth: double.infinity,
                    buttonHeight: 42.h,
                    cornerRadius: 12.r,
                    gradientColors: const [
                      AppColors.primaryDarkColor,
                      AppColors.primaryDarkButtonColor,
                    ],
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

/// Reads the persisted logged-in user from local storage. Returns `null` when
/// no user is cached (e.g. guest mode) or the cached payload is unreadable.
/// Opens the edit-profile screen (guests are prompted to sign in first) and
/// refreshes the cached-user UI when changes are saved.
Future<void> _onEditProfile(
  BuildContext context,
  UserModel? cachedUser,
  bool isGuest,
) async {
  if (isGuest || cachedUser == null) {
    AuthRequiredDialog.show(
      context,
      message: 'Please log in or create an account to edit your profile.',
    );
    return;
  }

  final saved = await Navigator.of(context).push<bool>(
    MaterialPageRoute(
      builder: (_) => EditProfileScreen(user: cachedUser),
      // Presented as a fullscreen dialog: disables the interactive swipe-back
      // pop gesture whose drag handler triggers a framework assertion
      // (`_userGesturesInProgress > 0`). Back button / system back still work.
      fullscreenDialog: true,
    ),
  );

  if (saved == true && context.mounted) {
    _onCachedUserChanged(context);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          backgroundColor: AppColors.primaryDarkColor,
        ),
      );
  }
}

/// Rebuilds the profile UI (and other cached-user readers) after the cached
/// user changed via an edit or photo upload. The cache itself was already
/// refreshed by the repository's `get_user` call.
void _onCachedUserChanged(BuildContext context) {
  try {
    context.read<ProfileCubit>().notifyUserUpdated();
  } catch (_) {
    // ProfileCubit not in scope — nothing to rebuild here.
  }
  try {
    context.read<UserBloc>().add(const OnLoadCustomerFromCache());
  } catch (_) {
    // UserBloc not in scope — the cache was still refreshed.
  }
}

UserModel? _readCachedUser(LocalStorageService storage) {
  final jsonString = storage.read<String>(StorageConstants.cachedUser);
  if (jsonString == null || jsonString.isEmpty) return null;
  try {
    final decoded = json.decode(jsonString);
    if (decoded is! Map) return null;
    return UserModel.fromJson(Map<String, dynamic>.from(decoded));
  } catch (_) {
    return null;
  }
}

/// Actions offered by the profile-photo bottom sheet.
enum _PhotoSheetAction { camera, gallery, remove }

class _ProfileHeader extends StatefulWidget {
  const _ProfileHeader({required this.state});

  final ProfileLoaded state;

  @override
  State<_ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<_ProfileHeader> {
  final ImagePicker _picker = ImagePicker();
  bool _uploading = false;

  /// Lets the user pick a source, then uploads the chosen image and refreshes
  /// the cached user. Guests are prompted to sign in.
  Future<void> _onChangePhoto() async {
    if (_uploading) return;

    final storage = sl<LocalStorageService>();
    if (storage.isGuest) {
      AuthRequiredDialog.show(
        context,
        message: 'Please log in or create an account to set a profile photo.',
      );
      return;
    }

    // Offer "Remove Photo" only when the user actually has one set.
    final cachedUser = _readCachedUser(storage);
    final hasPhoto = (cachedUser?.avatarUrl ?? '').isNotEmpty;

    final action = await _pickImageSource(hasPhoto: hasPhoto);
    if (action == null || !mounted) return;

    if (action == _PhotoSheetAction.remove) {
      await _onRemovePhoto();
      return;
    }

    final source = action == _PhotoSheetAction.camera
        ? ImageSource.camera
        : ImageSource.gallery;

    // Camera capture needs an explicit runtime permission; the gallery uses the
    // system photo picker which doesn't.
    if (source == ImageSource.camera) {
      final allowed = await _ensureCameraPermission();
      if (!allowed || !mounted) return;
    }

    XFile? picked;
    try {
      picked = await _picker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
    } on PlatformException catch (e) {
      if (!mounted) return;
      // image_picker surfaces an OS-level permission block here (e.g. the photo
      // library is denied/restricted) — route the user to Settings.
      if (e.code == 'camera_access_denied' ||
          e.code == 'photo_access_denied') {
        await _showPermissionSettingsDialog(
          title: source == ImageSource.camera
              ? 'Camera access needed'
              : 'Photo access needed',
          message: source == ImageSource.camera
              ? 'Enable camera access in Settings to take a profile photo.'
              : 'Enable photo access in Settings to choose a profile photo.',
        );
      } else {
        _showError(
          'Could not open the '
          '${source == ImageSource.camera ? 'camera' : 'gallery'}.',
        );
      }
      return;
    } catch (_) {
      if (!mounted) return;
      _showError(
        'Could not open the '
        '${source == ImageSource.camera ? 'camera' : 'gallery'}.',
      );
      return;
    }
    if (picked == null) return; // user cancelled

    setState(() => _uploading = true);

    // The API only accepts jpg/jpeg/png. Anything else (webp, heic, …) is
    // converted to PNG on a background isolate before uploading.
    final String uploadPath;
    try {
      uploadPath = await ensureUploadableImage(picked.path);
    } on UnsupportedImageException catch (e) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showError(e.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      _showError('Could not process the selected image. Please try another.');
      return;
    }

    final result = await sl<UploadUserPictureUseCase>()(uploadPath);
    if (!mounted) return;
    setState(() => _uploading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (_) {
        _onCachedUserChanged(context);
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text('Profile photo updated.'),
              backgroundColor: AppColors.primaryDarkColor,
            ),
          );
      },
    );
  }

  Future<_PhotoSheetAction?> _pickImageSource({required bool hasPhoto}) {
    final ui = AppUiColors.of(context);
    return showModalBottomSheet<_PhotoSheetAction>(
      context: context,
      backgroundColor: ui.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              12.verticalSpace,
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ui.borderSubtle,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              8.verticalSpace,
              ListTile(
                leading: Icon(Icons.photo_camera_outlined,
                    color: ui.brandPrimary),
                title: AppText(
                  'Take Photo',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight500,
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoSheetAction.camera),
              ),
              ListTile(
                leading:
                    Icon(Icons.photo_library_outlined, color: ui.brandPrimary),
                title: AppText(
                  'Choose from Gallery',
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight500,
                ),
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoSheetAction.gallery),
              ),
              // Only offer removal when there's a photo to remove.
              if (hasPhoto)
                ListTile(
                  leading: Icon(Icons.delete_outline_rounded,
                      color: AppColors.removeColor),
                  title: AppText(
                    'Remove Photo',
                    color: AppColors.removeColor,
                    fontSize: FontSizes.font14Sp,
                    fontWeight: FontWeights.weight500,
                  ),
                  onTap: () =>
                      Navigator.of(sheetContext).pop(_PhotoSheetAction.remove),
                ),
              8.verticalSpace,
            ],
          ),
        );
      },
    );
  }

  /// Confirms, then deletes the profile picture via `delete_user_picture` and
  /// refreshes the cached user. Guest / no-photo cases are already filtered out
  /// before this is reached. Best-effort with full error surfacing.
  Future<void> _onRemovePhoto() async {
    if (_uploading) return;

    final confirmed = await _showRemovePhotoDialog();
    if (confirmed != true || !mounted) return;

    setState(() => _uploading = true);

    final result = await sl<DeleteUserPictureUseCase>()(const NoParams());
    if (!mounted) return;
    setState(() => _uploading = false);

    result.fold(
      (failure) => _showError(failure.message),
      (_) {
        _onCachedUserChanged(context);
        Fluttertoast.showToast(
          msg: 'Profile photo removed.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      },
    );
  }

  /// Confirmation dialog for removing the profile picture. Returns `true` when
  /// the user confirms.
  Future<bool?> _showRemovePhotoDialog() {
    final ui = AppUiColors.of(context);
    return showDialog<bool>(
      context: context,
      barrierColor: AppColors.blackColor.withValues(alpha: 0.55),
      builder: (dialogContext) => Dialog(
        backgroundColor: ui.cardBackground,
        insetPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18.r)),
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
                      'Remove Photo',
                      color: ui.textPrimary,
                      fontSize: FontSizes.font18Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
                ],
              ),
              14.verticalSpace,
              AppText(
                'Are you sure you want to remove your profile photo?',
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
                      text: 'Remove',
                      onPress: () => Navigator.of(dialogContext).pop(true),
                      buttonWidth: double.infinity,
                      buttonHeight: 42.h,
                      cornerRadius: 12.r,
                      gradientColors: const [
                        AppColors.primaryDarkColor,
                        AppColors.primaryDarkButtonColor,
                      ],
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

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: AppColors.removeColor,
        ),
      );
  }

  /// Ensures the camera permission is granted, covering every state:
  /// granted, denied (re-asked), permanently denied / restricted (→ Settings).
  /// Returns true only when the camera may be used.
  Future<bool> _ensureCameraPermission() async {
    var status = await Permission.camera.status;

    // iOS parental controls — the user can't grant it; point to Settings.
    if (status.isRestricted) {
      if (!mounted) return false;
      await _showPermissionSettingsDialog(
        title: 'Camera unavailable',
        message:
            'Camera access is restricted on this device and can\'t be enabled '
            'here. Check your device restrictions in Settings.',
      );
      return false;
    }

    // Already blocked at the OS level — only Settings can re-enable it.
    if (status.isPermanentlyDenied) {
      if (!mounted) return false;
      await _showPermissionSettingsDialog(
        title: 'Camera access needed',
        message:
            'Camera access is turned off. Enable it in Settings to take a '
            'profile photo.',
      );
      return false;
    }

    // First time / previously denied but re-askable → prompt the OS dialog.
    if (!status.isGranted) {
      status = await Permission.camera.request();
    }

    if (status.isGranted) return true;

    if (!mounted) return false;
    if (status.isPermanentlyDenied || status.isRestricted) {
      await _showPermissionSettingsDialog(
        title: 'Camera access needed',
        message:
            'Camera access is turned off. Enable it in Settings to take a '
            'profile photo.',
      );
    } else {
      // Plain denial for this attempt.
      _showError('Camera permission is required to take a photo.');
    }
    return false;
  }

  /// Confirmation dialog that deep-links to the OS app settings.
  Future<void> _showPermissionSettingsDialog({
    required String title,
    required String message,
  }) async {
    final ui = AppUiColors.of(context);
    final goToSettings = await showDialog<bool>(
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
                      color: ui.brandPrimary.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.photo_camera_outlined,
                      color: ui.brandPrimary,
                      size: 22.r,
                    ),
                  ),
                  12.horizontalSpace,
                  Expanded(
                    child: AppText(
                      title,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font18Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
                ],
              ),
              14.verticalSpace,
              AppText(
                message,
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
                      text: 'Open Settings',
                      onPress: () => Navigator.of(dialogContext).pop(true),
                      buttonWidth: double.infinity,
                      buttonHeight: 42.h,
                      cornerRadius: 12.r,
                      gradientColors: const [
                        AppColors.primaryDarkColor,
                        AppColors.primaryDarkButtonColor,
                      ],
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

    if (goToSettings == true) {
      await openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final cubit = context.read<ProfileCubit>();
    final profile = widget.state.profile;
    final bottomRadius = 20.r;

    // Prefer the persisted logged-in user; fall back to guest, then profile.
    final storage = sl<LocalStorageService>();
    final cachedUser = _readCachedUser(storage);
    final isGuest = storage.isGuest || cachedUser == null;

    final displayName = isGuest
        ? 'Guest User'
        : (cachedUser.name.isNotEmpty ? cachedUser.name : profile.name);
    final displayEmail = isGuest
        ? 'Sign in to sync your account'
        : (cachedUser.email.isNotEmpty ? cachedUser.email : profile.email);
    // Profile image comes from the getUser response (`profile_img_url`).
    final avatarUrl = isGuest ? null : cachedUser.avatarUrl;

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
                    backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                        ? NetworkImage(avatarUrl)
                        : null,
                    child: (avatarUrl == null || avatarUrl.isEmpty)
                        ? Icon(
                            Icons.person_rounded,
                            size: 40.r,
                            color: AppColors.whiteColor,
                          )
                        : null,
                  ),
                  // Dim + spinner while a new photo is uploading.
                  if (_uploading)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.blackColor.withValues(alpha: 0.45),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: const CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.whiteColor,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: -2,
                    bottom: -2,
                    child: GestureDetector(
                      onTap: _uploading ? null : _onChangePhoto,
                      behavior: HitTestBehavior.opaque,
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
                  ),
                ],
              ),
              14.horizontalSpace,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    10.verticalSpace,
                    AppText(
                      displayName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font20Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      displayEmail,
                      color: ui.textSecondary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    // if (memberSince != null) ...[
                    //   4.verticalSpace,
                    //   AppText(
                    //     memberSince,
                    //     color: ui.textSecondary,
                    //     fontSize: FontSizes.font12Sp,
                    //     fontWeight: FontWeights.weight400,
                    //   ),
                    // ],
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
                  selected: widget.state.mainTab == ProfileMainTab.profile,
                  onTap: () => cubit.setMainTab(ProfileMainTab.profile),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _HeaderTabChip(
                  label: 'Vehicles',
                  icon: Icons.directions_car_outlined,
                  selected: widget.state.mainTab == ProfileMainTab.vehicles,
                  onTap: () => cubit.setMainTab(ProfileMainTab.vehicles),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: _HeaderTabChip(
                  label: 'Settings',
                  icon: Icons.settings_outlined,
                  selected: widget.state.mainTab == ProfileMainTab.settings,
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

/// Charging stats grid backed by `charging_stats`. Shows per-tile spinners
/// while loading, dashes + a retry affordance on failure, and zeroed values
/// for guests / brand-new accounts.
class _StatsGrid extends StatelessWidget {
  /// Trims a trailing `.0` (40.0 → "40", 40.8 → "40.8").
  String _trimNum(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  /// Groups an integer with thousands separators (5930 → "5,930").
  String _grouped(num v) {
    final s = v.toInt().toString();
    final neg = s.startsWith('-');
    final digits = neg ? s.substring(1) : s;
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i != 0 && (digits.length - i) % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return neg ? '-$buf' : buf.toString();
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return BlocBuilder<ChargingStatsCubit, ChargingStatsState>(
      builder: (context, state) {
        final stats = state.stats;
        final loading = state.isLoading && stats == null;
        final failed = state.isFailure && stats == null;

        final charges = stats != null ? _grouped(stats.totalCharges) : '—';
        final kwh = stats != null ? _trimNum(stats.totalKwh) : '—';
        final money =
            stats != null ? 'PKR ${_grouped(stats.moneySavedPkr)}' : '—';
        final co2 =
            stats != null ? '${_trimNum(stats.co2ReducedKg)} kg' : '—';

        return Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    icon: Icons.bolt_rounded,
                    iconBg: AppColors.transparentColor,
                    iconColor: ui.brandSecondary,
                    value: charges,
                    valueColor: ui.textPrimary,
                    label: 'Total Charging Sessions',
                    isLoading: loading,
                    valueLeftPadding: 4.0,
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: _StatTile(
                    icon: Icons.battery_charging_full_rounded,
                    iconBg: AppColors.transparentColor,
                    iconColor: ui.brandSecondary,
                    value: kwh,
                    valueColor: ui.textPrimary,
                    label: 'kWh Charged',
                    isLoading: loading,
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
                    value: money,
                    valueColor: ui.textPrimary,
                    label: 'Money Saved',
                    isLoading: loading,
                  ),
                ),
                10.horizontalSpace,
                Expanded(
                  child: _StatTile(
                    icon: Icons.eco_outlined,
                    iconBg: AppColors.transparentColor,
                    iconColor: ui.brandSecondary,
                    value: co2,
                    valueColor: ui.textPrimary,
                    label: 'CO2 Reduced',
                    isLoading: loading,
                  ),
                ),
              ],
            ),
            if (failed) ...[
              8.verticalSpace,
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline_rounded,
                      size: 14.r, color: ui.textSecondary),
                  6.horizontalSpace,
                  Flexible(
                    child: AppText(
                      state.error ?? 'Couldn\'t load your stats.',
                      color: ui.textSecondary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  10.horizontalSpace,
                  GestureDetector(
                    onTap: () => context.read<ChargingStatsCubit>().load(),
                    behavior: HitTestBehavior.opaque,
                    child: AppText(
                      'Retry',
                      color: ui.brandPrimary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ),
                ],
              ),
            ],
          ],
        );
      },
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
    this.isLoading = false,
    this.valueLeftPadding = 0,
  });

  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;

  /// When true, a small spinner replaces the value while stats load.
  final bool isLoading;

  /// Left inset applied to the value only (used to nudge a specific tile).
  final double valueLeftPadding;

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
          // Shift left by the icon glyph's built-in optical padding so its
          // visible edge lines up flush with the value/label text below.
          Transform.translate(
            offset: Offset(-2.r, 0),
            child: Container(
              padding: EdgeInsets.zero,
              decoration: BoxDecoration(
                color: iconBg,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24.r),
            ),
          ),
          10.verticalSpace,
          SizedBox(
            height: 24.h,
            child: Padding(
              padding: EdgeInsets.only(left: valueLeftPadding),
              child: isLoading
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 16.r,
                        height: 16.r,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: ui.brandPrimary,
                        ),
                      ),
                    )
                  : AppText(
                      value,
                      color: valueColor,
                      fontSize: FontSizes.font18Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            ),
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
    final storage = sl<LocalStorageService>();
    final cachedUser = _readCachedUser(storage);
    final isGuest = storage.isGuest || cachedUser == null;

    final displayName = isGuest
        ? 'Guest User'
        : (cachedUser.name.isNotEmpty ? cachedUser.name : profile.name);
    final displayEmail = isGuest
        ? 'Sign in to sync your account'
        : (cachedUser.email.isNotEmpty ? cachedUser.email : profile.email);
    final displayPhone = isGuest
        ? null
        : _formatCachedUserPhone(cachedUser) ?? profile.phone;

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
                onPress: () => _onEditProfile(context, cachedUser, isGuest),
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
          _KeyValueRow(label: 'Full Name', value: displayName),
          _DividerLine(),
          _KeyValueRow(label: 'Email', value: displayEmail),
          if (displayPhone != null && displayPhone.isNotEmpty) ...[
            _DividerLine(),
            _KeyValueRow(label: 'Phone', value: displayPhone),
          ],
        ],
      ),
    );
  }
}

/// Formats the cached user's phone with country code when available.
String? _formatCachedUserPhone(UserModel user) {
  final phone = user.phoneNumber;
  if (phone == null || phone.isEmpty) return null;
  final code = user.countryCode;
  if (code != null && code.isNotEmpty) return '$code $phone';
  return phone;
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
        child: const _AddVehicleDialog(),
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
    final confirmed = await _showDeleteVehicleDialog(context, vehicle);
    if (confirmed != true || !mounted) return;

    final result = await cubit.deleteVehicle(vehicle.id);
    if (!mounted) return;

    if (result.success) {
      // Removing a vehicle changes the user object — refresh the cached user.
      unawaited(_refreshCachedUser());
      return;
    }

    // Surface failures (e.g. "Vehicle not found.").
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(result.message),
          backgroundColor: AppColors.removeColor,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
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
            _buildBody(ui, state),
          ],
        );
      },
    );
  }

  Widget _buildBody(AppUiColors ui, VehicleState state) {
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
                child: _VehicleCard(
                  vehicle: vehicle,
                  isDeleting: state.isDeleting(vehicle.id),
                  onDelete: () => _deleteVehicle(vehicle),
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

/// Confirms a destructive vehicle delete. Returns `true` when the user confirms.
Future<bool?> _showDeleteVehicleDialog(
  BuildContext context,
  UserVehicleEntity vehicle,
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
              'Are you sure you want to delete "${vehicle.displayName}"? '
              'This action cannot be undone.',
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

/// Add-vehicle dialog. Make/model dropdowns are populated from the vehicle
/// APIs; submitting calls `add-vehicle` and refreshes the user's vehicle list.
class _AddVehicleDialog extends StatefulWidget {
  const _AddVehicleDialog();

  @override
  State<_AddVehicleDialog> createState() => _AddVehicleDialogState();
}

class _AddVehicleDialogState extends State<_AddVehicleDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _rfidController = TextEditingController();

  int? _selectedMakeId;
  int? _selectedModelId;
  String? _selectedYear;

  late final List<String> _years = _buildYears();

  static List<String> _buildYears() {
    final currentYear = DateTime.now().year;
    return [
      for (var y = currentYear + 1; y >= 1990; y--) y.toString(),
    ];
  }

  @override
  void initState() {
    super.initState();
    final cubit = context.read<VehicleCubit>();
    // Reset any stale models and ensure makes are loaded for the dropdown.
    cubit.resetModels();
    if (cubit.state.makesStatus != VehicleStatus.success) {
      cubit.loadMakes();
    }
  }

  @override
  void dispose() {
    _rfidController.dispose();
    super.dispose();
  }

  void _onMakeChanged(int? makeId) {
    if (makeId == null || makeId == _selectedMakeId) return;
    setState(() {
      _selectedMakeId = makeId;
      _selectedModelId = null;
    });
    context.read<VehicleCubit>().loadModels(makeId);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final cubit = context.read<VehicleCubit>();
    final result = await cubit.addVehicle(
      mdMake: _selectedMakeId!,
      mdModel: _selectedModelId!,
      year: _selectedYear!,
      // Registration number (sent to the API as `vehicle_reg`) is now required.
      vehicleRfid: _rfidController.text.trim(),
    );

    if (!mounted) return;
    if (result.success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(result.message),
            backgroundColor: AppColors.removeColor,
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return BlocBuilder<VehicleCubit, VehicleState>(
      builder: (context, state) {
        return Dialog(
          backgroundColor: ui.cardBackground,
          insetPadding:
              EdgeInsets.symmetric(horizontal: 24.w, vertical: 24.h),
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
                            'Add New Vehicle',
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
                      'Select your vehicle details below.',
                      color: ui.textSecondary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                    ),
                    18.verticalSpace,
                    _buildMakeField(ui, state),
                    14.verticalSpace,
                    _buildModelField(ui, state),
                    14.verticalSpace,
                    _VehicleDropdownField<String>(
                      ui: ui,
                      label: 'Year',
                      hintText: 'Select year',
                      value: _selectedYear,
                      items: [
                        for (final y in _years)
                          DropdownMenuItem<String>(
                            value: y,
                            child: AppText(
                              y,
                              color: ui.textPrimary,
                              fontSize: FontSizes.font14Sp,
                              fontWeight: FontWeights.weight500,
                            ),
                          ),
                      ],
                      validator: (v) => v == null ? 'Year is required' : null,
                      onChanged: (v) => setState(() => _selectedYear = v),
                    ),
                    14.verticalSpace,
                    _buildRfidField(ui),
                    22.verticalSpace,
                    Row(
                      children: [
                        Expanded(
                          child: PrimaryButtonWidget(
                            text: 'Cancel',
                            onPress: state.isSubmitting
                                ? () {}
                                : () => Navigator.of(context).pop(),
                            buttonWidth: double.infinity,
                            buttonHeight: 38.h,
                            cornerRadius: 24.r,
                            buttonColor: ui.chipInactiveBg,
                            strokeColor: ui.borderSubtle,
                            textColor: ui.textPrimary,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight600,
                          ),
                        ),
                        12.horizontalSpace,
                        Expanded(
                          child: state.isSubmitting
                              ? Container(
                                  height: 38.h,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24.r),
                                    gradient: const LinearGradient(
                                      colors: [
                                        AppColors.primaryDarkColor,
                                        AppColors.primaryDarkButtonColor,
                                      ],
                                    ),
                                  ),
                                  child: SizedBox(
                                    width: 18.r,
                                    height: 18.r,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.whiteColor,
                                    ),
                                  ),
                                )
                              : PrimaryButtonWidget(
                                  text: 'Add Vehicle',
                                  onPress: _submit,
                                  buttonWidth: double.infinity,
                                  buttonHeight: 38.h,
                                  cornerRadius: 24.r,
                                  gradientColors: const [
                                    AppColors.primaryDarkColor,
                                    AppColors.primaryDarkButtonColor,
                                  ],
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
      },
    );
  }

  Widget _buildMakeField(AppUiColors ui, VehicleState state) {
    if (state.makesStatus == VehicleStatus.failure) {
      return _DropdownErrorField(
        ui: ui,
        label: 'Make',
        message: state.makesError ?? 'Could not load makes.',
        onRetry: () => context.read<VehicleCubit>().loadMakes(),
      );
    }
    return _VehicleDropdownField<int>(
      ui: ui,
      label: 'Make',
      hintText: state.makesStatus == VehicleStatus.loading
          ? 'Loading makes...'
          : 'Select make',
      value: _selectedMakeId,
      isLoading: state.makesStatus == VehicleStatus.loading,
      enabled: state.makesStatus == VehicleStatus.success,
      items: [
        for (final make in state.makes)
          DropdownMenuItem<int>(
            value: make.id,
            child: AppText(
              make.name,
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
            ),
          ),
      ],
      validator: (v) => v == null ? 'Make is required' : null,
      onChanged: _onMakeChanged,
    );
  }

  Widget _buildModelField(AppUiColors ui, VehicleState state) {
    if (_selectedMakeId != null &&
        state.modelsStatus == VehicleStatus.failure) {
      return _DropdownErrorField(
        ui: ui,
        label: 'Model',
        message: state.modelsError ?? 'Could not load models.',
        onRetry: () =>
            context.read<VehicleCubit>().loadModels(_selectedMakeId!),
      );
    }
    final hasModels = state.models.isNotEmpty;
    final loading = state.modelsStatus == VehicleStatus.loading;
    return _VehicleDropdownField<int>(
      ui: ui,
      label: 'Model',
      hintText: _selectedMakeId == null
          ? 'Select make first'
          : loading
              ? 'Loading models...'
              : (hasModels ? 'Select model' : 'No models available'),
      value: _selectedModelId,
      isLoading: loading,
      enabled: _selectedMakeId != null && hasModels && !loading,
      items: [
        for (final model in state.models)
          DropdownMenuItem<int>(
            value: model.id,
            child: AppText(
              model.connectorType != null && model.connectorType!.isNotEmpty
                  ? '${model.name} · ${model.connectorType}'
                  : model.name,
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight500,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
      validator: (v) => v == null ? 'Model is required' : null,
      onChanged: (v) => setState(() => _selectedModelId = v),
    );
  }

  Widget _buildRfidField(AppUiColors ui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          'Vehicle Registration Number',
          color: ui.textPrimary,
          fontSize: FontSizes.font12Sp,
          fontWeight: FontWeights.weight600,
        ),
        6.verticalSpace,
        TextFormField(
          controller: _rfidController,
          textCapitalization: TextCapitalization.characters,
          validator: (v) {
            final value = v?.trim() ?? '';
            if (value.isEmpty) return 'Registration number is required';
            if (value.length < 3) {
              return 'Enter a valid registration number';
            }
            return null;
          },
          style: TextStyle(
            color: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
            fontFamily: AppFonts.lexend,
          ),
          decoration: InputDecoration(
            filled: true,
            fillColor: ui.inputFill,
            isDense: true,
            hintText: 'e.g. ABC-123',
            hintStyle: TextStyle(
              color: AppColors.hintColor,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight400,
              fontFamily: AppFonts.lexend,
            ),
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

/// A labelled dropdown matching the dialog's field styling.
class _VehicleDropdownField<T> extends StatelessWidget {
  const _VehicleDropdownField({
    required this.ui,
    required this.label,
    required this.hintText,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.enabled = true,
    this.isLoading = false,
  });

  final AppUiColors ui;
  final String label;
  final String hintText;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  final String? Function(T?)? validator;
  final bool enabled;
  final bool isLoading;

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
        DropdownButtonFormField<T>(
          initialValue: value,
          isExpanded: true,
          validator: validator,
          onChanged: enabled ? onChanged : null,
          icon: isLoading
              ? SizedBox(
                  width: 16.r,
                  height: 16.r,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: ui.textSecondary,
                  ),
                )
              : Icon(
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          items: items,
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

/// Inline error + retry shown in place of a dropdown when its data fails.
class _DropdownErrorField extends StatelessWidget {
  const _DropdownErrorField({
    required this.ui,
    required this.label,
    required this.message,
    required this.onRetry,
  });

  final AppUiColors ui;
  final String label;
  final String message;
  final VoidCallback onRetry;

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
        Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: ui.inputFill,
            borderRadius: BorderRadius.circular(12.r),
            border: const Border.fromBorderSide(
              BorderSide(color: AppColors.redColor),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: AppText(
                  message,
                  color: ui.textSecondary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight400,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              8.horizontalSpace,
              GestureDetector(
                onTap: onRetry,
                behavior: HitTestBehavior.opaque,
                child: AppText(
                  'Retry',
                  color: ui.brandPrimary,
                  fontSize: FontSizes.font12Sp,
                  fontWeight: FontWeights.weight700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _VehicleCard extends StatelessWidget {
  const _VehicleCard({
    required this.vehicle,
    this.onDelete,
    this.isDeleting = false,
  });

  final UserVehicleEntity vehicle;
  final VoidCallback? onDelete;
  final bool isDeleting;

  Widget _vehicleImage(AppUiColors ui) {
    final imageUrl = vehicle.modelImage;
    if (imageUrl == null || imageUrl.isEmpty) {
      return _vehicleImagePlaceholder(ui);
    }
    return Image.network(
      imageUrl,
      height: 140.h,
      width: double.infinity,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          height: 140.h,
          width: double.infinity,
          color: ui.vehicleImagePlaceholder,
          alignment: Alignment.center,
          child: SizedBox(
            width: 24.r,
            height: 24.r,
            child: CircularProgressIndicator(
              strokeWidth: 2.4,
              color: ui.brandPrimary,
            ),
          ),
        );
      },
      errorBuilder: (context, error, stackTrace) =>
          _vehicleImagePlaceholder(ui),
    );
  }

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

  String get _subtitle {
    final parts = <String>[
      if (vehicle.year.trim().isNotEmpty) vehicle.year.trim(),
      if (vehicle.connectorType.trim().isNotEmpty) vehicle.connectorType.trim(),
    ];
    return parts.join(' · ');
  }

  String _trimNum(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    final capacity = vehicle.batteryCapacity != null
        ? '${_trimNum(vehicle.batteryCapacity!)} kWh'
        : '—';
    final range = vehicle.range != null ? '${_trimNum(vehicle.range!)} km' : '—';
    final energy = '${_trimNum(vehicle.totalEnergyCharged)} kWh';

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
          _vehicleImage(ui),
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
                            vehicle.displayName,
                            color: ui.textPrimary,
                            fontSize: FontSizes.font14Sp,
                            fontWeight: FontWeights.weight700,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_subtitle.isNotEmpty) ...[
                            4.verticalSpace,
                            AppText(
                              _subtitle,
                              color: ui.textSecondary,
                              fontSize: FontSizes.font12Sp,
                              fontWeight: FontWeights.weight400,
                            ),
                          ],
                          if (vehicle.registrationNo != null &&
                              vehicle.registrationNo!.trim().isNotEmpty) ...[
                            6.verticalSpace,
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 14.r,
                                  color: ui.textSecondary,
                                ),
                                4.horizontalSpace,
                                Flexible(
                                  child: AppText(
                                    vehicle.registrationNo!.trim(),
                                    color: ui.textPrimary,
                                    fontSize: FontSizes.font12Sp,
                                    fontWeight: FontWeights.weight600,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (vehicle.connectorType.trim().isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: ui.brandPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: AppText(
                          vehicle.connectorType.trim(),
                          color: ui.brandPrimary,
                          fontSize: FontSizes.font10Sp,
                          fontWeight: FontWeights.weight700,
                        ),
                      ),
                    if (isDeleting)
                      Padding(
                        padding: EdgeInsets.only(left: 8.w),
                        child: SizedBox(
                          width: 22.r,
                          height: 22.r,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.removeColor,
                          ),
                        ),
                      )
                    else
                      IconButton(
                        onPressed: onDelete,
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: BoxConstraints(
                          minWidth: 32.r,
                          minHeight: 32.r,
                        ),
                        icon: Icon(
                          Icons.delete_outline_rounded,
                          color: AppColors.removeColor,
                          size: 22.r,
                        ),
                      ),
                  ],
                ),
                12.verticalSpace,
                Row(
                  children: [
                    Expanded(
                      child: _VehicleStatBox(
                        icon: Icons.battery_charging_full_rounded,
                        label: 'Capacity',
                        value: capacity,
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: _VehicleStatBox(
                        icon: Icons.route_outlined,
                        label: 'Range',
                        value: range,
                      ),
                    ),
                    8.horizontalSpace,
                    Expanded(
                      child: _VehicleStatBox(
                        icon: Icons.bolt_rounded,
                        label: 'Charges',
                        value: vehicle.totalCharges.toString(),
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
                      energy,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font14Sp,
                      fontWeight: FontWeights.weight700,
                    ),
                  ],
                ),
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

class _SettingsTabBody extends StatelessWidget {
  const _SettingsTabBody();

  /// Placeholder for not-yet-built settings entries.
  void _showComingSoon() {
    Fluttertoast.showToast(
      msg: 'Coming soon',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _NotificationPreferencesSection(),
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
                onTap: _showComingSoon,
              ),
              _DividerLine(),
              _AccountTile(
                icon: Icons.help_outline_rounded,
                label: 'Help & Support',
                onTap: _showComingSoon,
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
                  buttonColor: !isLight ? AppColors.whiteColor.withValues(alpha: 0.12) : null,
                  gradientColors: isLight ? [
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

/// Notifications card backed by the preferences API
/// (`GET/PATCH /api/v1/notifications/preferences/`). Each toggle is optimistic
/// and reverts on failure; rows lock individually while their PATCH is in
/// flight. Guests are prompted to sign in.
class _NotificationPreferencesSection extends StatelessWidget {
  const _NotificationPreferencesSection();

  @override
  Widget build(BuildContext context) {
    if (AppStorage.isGuest) {
      return _SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _NotificationsHeader(),
            12.verticalSpace,
            AppText(
              'Sign in to manage your notification preferences.',
              color: AppUiColors.of(context).textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight400,
            ),
          ],
        ),
      );
    }
    return BlocProvider(
      create: (_) => sl<NotificationPreferencesCubit>()..load(),
      child: const _NotificationPreferencesView(),
    );
  }
}

class _NotificationsHeader extends StatelessWidget {
  const _NotificationsHeader();

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Row(
      children: [
        Icon(Icons.notifications_outlined, color: ui.textMuted, size: 20.r),
        8.horizontalSpace,
        AppText(
          'Notifications',
          color: ui.textPrimary,
          fontSize: FontSizes.font16Sp,
          fontWeight: FontWeights.weight700,
        ),
      ],
    );
  }
}

class _NotificationPreferencesView extends StatelessWidget {
  const _NotificationPreferencesView();

  @override
  Widget build(BuildContext context) {
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
        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _NotificationsHeader(),
              8.verticalSpace,
              _buildBody(context, AppUiColors.of(context), state),
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
          padding: EdgeInsets.symmetric(vertical: 28.h),
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
          padding: EdgeInsets.symmetric(vertical: 16.h),
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NotificationRow(
              title: 'Charging Updates',
              subtitle: 'Get notified about charging status',
              value: prefs.chargingUpdates,
              onChanged:
                  handlerFor(NotificationPreferenceKey.chargingUpdates),
            ),
            _DividerLine(),
            _NotificationRow(
              title: 'Booking Reminders',
              subtitle: 'Reminders for upcoming bookings',
              value: prefs.bookingReminders,
              onChanged:
                  handlerFor(NotificationPreferenceKey.bookingReminders),
            ),
            _DividerLine(),
            _NotificationRow(
              title: 'Promotional Offers',
              subtitle: 'Special deals and discounts',
              value: prefs.promotionalOffers,
              onChanged:
                  handlerFor(NotificationPreferenceKey.promotionalOffers),
            ),
            _DividerLine(),
            _NotificationRow(
              title: 'App Updates',
              subtitle: 'New features and improvements',
              value: prefs.appUpdates,
              onChanged: handlerFor(NotificationPreferenceKey.appUpdates),
            ),
          ],
        );
    }
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

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/core/usecase/usecase.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/image_upload_helper.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/auth/domain/usecases/delete_user_picture_usecase.dart';
import 'package:orko_hubco/features/auth/domain/usecases/upload_user_picture_usecase.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_state.dart';
import 'package:orko_hubco/features/profile/presentation/utils/profile_actions.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/profile_confirm_dialog.dart';
import 'package:permission_handler/permission_handler.dart';

/// Actions offered by the profile-photo bottom sheet.
enum _PhotoSheetAction { camera, gallery, remove }

/// Header of the profile screen: avatar (with photo upload / removal), the
/// user's name and email, and the Profile / Vehicles / Settings tab chips.
class ProfileHeader extends StatefulWidget {
  const ProfileHeader({super.key, required this.state});

  final ProfileLoaded state;

  @override
  State<ProfileHeader> createState() => _ProfileHeaderState();
}

class _ProfileHeaderState extends State<ProfileHeader> {
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
        feature: 'profile',
        message: 'Please log in or create an account to set a profile photo.',
      );
      return;
    }

    // Offer "Remove Photo" only when the user actually has one set.
    final cachedUser = readCachedUser(storage);
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
        showErrorSnackBar(
          context,
          'Could not open the '
          '${source == ImageSource.camera ? 'camera' : 'gallery'}.',
        );
      }
      return;
    } catch (_) {
      if (!mounted) return;
      showErrorSnackBar(
        context,
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
      showErrorSnackBar(context, e.message);
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _uploading = false);
      showErrorSnackBar(
        context,
        'Could not process the selected image. Please try another.',
      );
      return;
    }

    final result = await sl<UploadUserPictureUseCase>()(uploadPath);
    if (!mounted) return;
    setState(() => _uploading = false);

    result.fold(
      (failure) => showErrorSnackBar(context, failure.message),
      (_) {
        notifyCachedUserChanged(context);
        showSuccessSnackBar(context, 'Profile photo updated.');
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
              _PhotoSheetTile(
                icon: Icons.photo_camera_outlined,
                iconColor: ui.brandPrimary,
                label: 'Take Photo',
                labelColor: ui.textPrimary,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoSheetAction.camera),
              ),
              _PhotoSheetTile(
                icon: Icons.photo_library_outlined,
                iconColor: ui.brandPrimary,
                label: 'Choose from Gallery',
                labelColor: ui.textPrimary,
                onTap: () =>
                    Navigator.of(sheetContext).pop(_PhotoSheetAction.gallery),
              ),
              // Only offer removal when there's a photo to remove.
              if (hasPhoto)
                _PhotoSheetTile(
                  icon: Icons.delete_outline_rounded,
                  iconColor: AppColors.removeColor,
                  label: 'Remove Photo',
                  labelColor: AppColors.removeColor,
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

    final confirmed = await showProfileConfirmDialog(
      context,
      icon: Icons.delete_outline_rounded,
      iconColor: AppColors.removeColor,
      title: 'Remove Photo',
      message: 'Are you sure you want to remove your profile photo?',
      confirmText: 'Remove',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _uploading = true);

    final result = await sl<DeleteUserPictureUseCase>()(const NoParams());
    if (!mounted) return;
    setState(() => _uploading = false);

    result.fold(
      (failure) => showErrorSnackBar(context, failure.message),
      (_) {
        notifyCachedUserChanged(context);
        Fluttertoast.showToast(
          msg: 'Profile photo removed.',
          toastLength: Toast.LENGTH_SHORT,
          gravity: ToastGravity.BOTTOM,
        );
      },
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
      showErrorSnackBar(context, 'Camera permission is required to take a photo.');
    }
    return false;
  }

  /// Confirmation dialog that deep-links to the OS app settings.
  Future<void> _showPermissionSettingsDialog({
    required String title,
    required String message,
  }) async {
    final goToSettings = await showProfileConfirmDialog(
      context,
      icon: Icons.photo_camera_outlined,
      iconColor: AppUiColors.of(context).brandPrimary,
      title: title,
      message: message,
      confirmText: 'Open Settings',
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
    final cachedUser = readCachedUser(storage);
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
              _ProfileAvatar(
                avatarUrl: avatarUrl,
                uploading: _uploading,
                onChangePhoto: _uploading ? null : _onChangePhoto,
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
                  ],
                ),
              ),
            ],
          ),
          16.verticalSpace,
          Row(
            children: [
              Expanded(
                child: HeaderTabChip(
                  label: 'Profile',
                  icon: Icons.person_outline_rounded,
                  selected: widget.state.mainTab == ProfileMainTab.profile,
                  onTap: () => cubit.setMainTab(ProfileMainTab.profile),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: HeaderTabChip(
                  label: 'Vehicles',
                  icon: Icons.directions_car_outlined,
                  selected: widget.state.mainTab == ProfileMainTab.vehicles,
                  onTap: () => cubit.setMainTab(ProfileMainTab.vehicles),
                ),
              ),
              8.horizontalSpace,
              Expanded(
                child: HeaderTabChip(
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

/// Circular avatar with an upload-in-progress overlay and the camera badge
/// that opens the change-photo sheet.
class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({
    required this.avatarUrl,
    required this.uploading,
    required this.onChangePhoto,
  });

  final String? avatarUrl;
  final bool uploading;
  final VoidCallback? onChangePhoto;

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CircleAvatar(
          radius: 38.r,
          backgroundColor: ui.textSecondary,
          backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
              ? NetworkImage(avatarUrl!)
              : null,
          child: (avatarUrl == null || avatarUrl!.isEmpty)
              ? Icon(
                  Icons.person_rounded,
                  size: 40.r,
                  color: AppColors.whiteColor,
                )
              : null,
        ),
        // Dim + spinner while a new photo is uploading.
        if (uploading)
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
            onTap: onChangePhoto,
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
    );
  }
}

/// One option row in the change-photo bottom sheet.
class _PhotoSheetTile extends StatelessWidget {
  const _PhotoSheetTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.labelColor,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final Color labelColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: AppText(
        label,
        color: labelColor,
        fontSize: FontSizes.font14Sp,
        fontWeight: FontWeights.weight500,
      ),
      onTap: onTap,
    );
  }
}

/// Pill-shaped main-tab selector chip shown in the profile header.
class HeaderTabChip extends StatelessWidget {
  const HeaderTabChip({
    super.key,
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
              width: selected ? 2.w : 1.w,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16.r,
                color: ui.textMuted,
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/storage_constants.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart';
import 'package:orko_hubco/core/services/local_storage_service.dart';
import 'package:orko_hubco/core/utils/widgets/auth_required_dialog.dart';
import 'package:orko_hubco/features/auth/data/models/user_model.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_state.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/screens/edit_profile_screen.dart';

/// Handles the Sign out action.
///
/// For guests there is no server session, so the logout API is skipped — we
/// just clear local user data and return to login. For authenticated users we
/// call the logout API first and only clear/navigate on success; a failure
/// surfaces a snackbar and leaves the user signed in.
Future<void> handleSignOut(BuildContext context) async {
  final storage = sl<LocalStorageService>();

  if (storage.isGuest) {
    await storage.setGuest(false);
    await clearUserData(storage);
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
  await clearUserData(storage);
  if (context.mounted) context.go('/login');
}

/// Removes this user's vehicle data while keeping app-level settings intact.
Future<void> clearUserData(LocalStorageService storage) async {
  await storage.remove(StorageConstants.vehicles);
  await storage.remove(StorageConstants.vehiclesInitialized);
}

/// Opens the edit-profile screen (guests are prompted to sign in first) and
/// refreshes the cached-user UI when changes are saved.
Future<void> openEditProfile(
  BuildContext context,
  UserModel? cachedUser,
  bool isGuest,
) async {
  if (isGuest || cachedUser == null) {
    AuthRequiredDialog.show(
      context,
      feature: 'profile',
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
    notifyCachedUserChanged(context);
    showSuccessSnackBar(context, 'Profile updated successfully.');
  }
}

/// Rebuilds the profile UI (and other cached-user readers) after the cached
/// user changed via an edit or photo upload. The cache itself was already
/// refreshed by the repository's `get_user` call.
void notifyCachedUserChanged(BuildContext context) {
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

/// Reads the persisted logged-in user from local storage. Returns `null` when
/// no user is cached (e.g. guest mode) or the cached payload is unreadable.
UserModel? readCachedUser(LocalStorageService storage) {
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

/// Formats the cached user's phone with country code when available.
String? formatCachedUserPhone(UserModel user) {
  final phone = user.phoneNumber;
  if (phone == null || phone.isEmpty) return null;
  final code = user.countryCode;
  if (code != null && code.isNotEmpty) return '$code $phone';
  return phone;
}

/// Replaces the current snackbar with a red error snackbar.
void showErrorSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.removeColor,
      ),
    );
}

/// Replaces the current snackbar with a brand-colored success snackbar.
void showSuccessSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.primaryDarkColor,
      ),
    );
}

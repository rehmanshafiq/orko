import 'package:flutter/material.dart';

class AppColors {
  static const kPrimaryColor = Color(0xFF3D3D33);
  static const whiteColor = Color(0xFFFFFFFF);
  static const blackColor = Color(0xFF000000);
  static const redColor = Color(0xFFDD1212);
  static const scaffoldColor = Color(0xFFFFFFFF);
  static const dividerColor = Color(0xFFDADADA);
  static const maroonColor = Color(0xFFA04838);
  static const removeColor = Color(0xFFDA3737);
  static const linearProgressBorderColor = Color(0xFFEDEDED);
  static const transparentColor = Colors.transparent;
  static const greyColor = Color(0xFF6E6E6E);
  static const iconsGreyColor = Color(0xFFA9A9A9);
  static const thumbBarGreyColor = Color(0xFFCCCCCC);
  static const shimmerGreyColor = Color(0xFFEEEEEE);
  static const shimmerHighlightColor = Color(0xFFE0E0E0);
  static const greyBottomSheetThumbColor = Color(0xFFCCCCCC);
  static const greyGridBoxColor = Color(0xFFDBDBDB);
  static const hintColor = Color(0xFFB6B6B6);
  static const sandColor = Color(0xFFE8E6DC);
  static const myAccountBorderColor = Color(0xFFE2E2E2);
  static const colorsOutlineColor = Color(0xFFEBEBEB);
  static const primaryLightColor = Color(0xFF8FC84D);
  static const primaryDarkColor = Color(0xFF329748);
  static const fieldBackgroundColor = Color(0xFF202221);
  static const mapPinBlueColor = Color(0xFF2A83FF);
  /// Star icons on reviews / ratings (warm gold on dark UI).
  static const ratingStarColor = Color(0xFFFFB74D);
  static const bottomNavBackgroundColor = Color(0xFF191919);
  /// Busy / warning time slots (mustard on dark UI).
  static const slotBusyYellowColor = Color(0xFF9A7B1E);
  /// Booked / unavailable slot chip background.
  static const slotBookedBackgroundColor = Color(0xFF5C2424);
}

/// Surfaces and typography that follow [ThemeData.brightness], built from [AppColors] only.
class AppUiColors {
  const AppUiColors._(this._brightness);

  factory AppUiColors.of(BuildContext context) {
    return AppUiColors._(Theme.of(context).brightness);
  }

  final Brightness _brightness;

  bool get isLight => _brightness == Brightness.light;

  Color get scaffoldBackground =>
      isLight ? AppColors.scaffoldColor : AppColors.blackColor;

  Color get cardBackground =>
      isLight ? AppColors.whiteColor : AppColors.fieldBackgroundColor;

  Color get textPrimary =>
      isLight ? AppColors.blackColor : AppColors.whiteColor;

  Color get textSecondary =>
      isLight ? AppColors.greyColor : AppColors.iconsGreyColor;

  Color get textMuted => isLight
      ? AppColors.hintColor
      : AppColors.whiteColor.withValues(alpha: 0.6);

  Color get borderSubtle => isLight
      ? AppColors.colorsOutlineColor
      : AppColors.whiteColor.withValues(alpha: 0.08);

  Color get progressTrack => isLight
      ? AppColors.shimmerGreyColor
      : AppColors.whiteColor.withValues(alpha: 0.12);

  Color get innerCardBg => isLight
      ? AppColors.sandColor.withValues(alpha: 0.55)
      : AppColors.fieldBackgroundColor;

  Color get vehicleImagePlaceholder => isLight
      ? AppColors.shimmerGreyColor
      : AppColors.greyColor.withValues(alpha: 0.25);

  Color get vehicleStatBoxBg => isLight
      ? AppColors.shimmerGreyColor
      : AppColors.whiteColor.withValues(alpha: 0.06);

  Color get bottomNavContainerBg =>
      isLight ? AppColors.whiteColor : AppColors.bottomNavBackgroundColor;

  Color get bottomNavBorder => isLight
      ? AppColors.colorsOutlineColor
      : AppColors.whiteColor.withValues(alpha: 0.06);

  Color get bottomNavShadow => isLight
      ? AppColors.blackColor.withValues(alpha: 0.08)
      : AppColors.blackColor.withValues(alpha: 0.4);

  Color get navInactive => isLight
      ? AppColors.greyColor
      : AppColors.whiteColor.withValues(alpha: 0.68);

  Color get navActive => AppColors.primaryDarkColor;

  Color get chipInactiveBg =>
      isLight ? AppColors.whiteColor : AppColors.fieldBackgroundColor;

  Color get chipInactiveBorder => borderSubtle;

  Color get drivingEfficiencyBg => isLight
      ? AppColors.mapPinBlueColor.withValues(alpha: 0.08)
      : AppColors.mapPinBlueColor.withValues(alpha: 0.12);

  Color get drivingEfficiencyBorder => isLight
      ? AppColors.mapPinBlueColor.withValues(alpha: 0.2)
      : AppColors.mapPinBlueColor.withValues(alpha: 0.25);

  Color get chargingPatternsBg => isLight
      ? AppColors.mapPinBlueColor.withValues(alpha: 0.06)
      : AppColors.mapPinBlueColor.withValues(alpha: 0.1);

  Color get chargingPatternsBorder => isLight
      ? AppColors.mapPinBlueColor.withValues(alpha: 0.18)
      : AppColors.mapPinBlueColor.withValues(alpha: 0.22);

  Color get efficiencyTipBg => isLight
      ? AppColors.primaryDarkColor.withValues(alpha: 0.1)
      : AppColors.primaryDarkColor.withValues(alpha: 0.2);

  Color get inputFill =>
      isLight ? AppColors.shimmerGreyColor : AppColors.fieldBackgroundColor;

  Color get inputBorder => isLight
      ? AppColors.dividerColor
      : AppColors.whiteColor.withValues(alpha: 0.16);

  Color get dividerLine =>
      isLight ? AppColors.dividerColor : AppColors.whiteColor.withValues(alpha: 0.2);

  Color get socialButtonShadow => isLight
      ? AppColors.blackColor.withValues(alpha: 0.08)
      : AppColors.blackColor.withValues(alpha: 0.45);
}

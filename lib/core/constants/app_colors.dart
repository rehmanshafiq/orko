import 'package:flutter/material.dart';

class AppColors {
  static const kPrimaryColor = Color(0xFF3D3D33);
  static const whiteColor = Color(0xFFFFFFFF);
  static const blackColor = Color(0xFF000000);
  static const redColor = Color(0xFFDD1212);
  static const scaffoldColor = Color(0xFFFFFFFF);
  /// App scaffold background in dark mode.
  static const darkScaffoldBackgroundColor = Color(0xFF1F2121);
  static const dividerColor = Color(0xFFDADADA);
  static const maroonColor = Color(0xFFA04838);
  static const removeColor = Color(0xFFDA3737);
  static const redButtonColor = Color(0xFF481818);
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
  static const greyBorderColor = Color(0xFF6A6B6D);
  static const primaryLightDarkColor = Color(0xFF699836);
  static const primaryDarkButtonColor = Color(0xFF1C5528);
  /// Brand button gradient stops (top → bottom), shared by primary buttons and toggles.
  static const List<Color> brandButtonGradientColors = [
    primaryLightDarkColor,
    primaryDarkButtonColor,
  ];
  static LinearGradient get brandButtonGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: brandButtonGradientColors,
      );
  static const primaryDarkColorTopGradient = Color(0xFF329748);
  /// Light green Pantone — primary on light surfaces, secondary on dark surfaces.
  static const primaryLightColor = Color(0xFF8FCF4D);
  /// Dark green Pantone — primary on dark surfaces, secondary on light surfaces.
  static const primaryDarkColor = Color(0xFF329748);
  static const primaryDarkColorMap = Color(0xFF4ADE80);
  static const primaryDarkColorMap2 = Color(0xFF58D68D);
  static const fieldBackgroundColor = Color(0xFF171717);
  static const fieldBackgroundBookingColor = Color(0xFF27252B);
  static const mapPinBlueColor = Color(0xFF2A83FF);
  /// Star icons on reviews / ratings (warm gold on dark UI).
  static const ratingStarColor = Color(0xFFFFB74D);
  static const ratingStarDarkColor = Color(0xFF996E2E);
  static const bottomNavBackgroundColor = Color(0xFF191919);
  /// Busy / warning time slots (mustard on dark UI).
  static const slotBusyYellowColor = Color(0xFF9A7B1E);
  /// Pale-yellow outline of the "No Show" booking badge.
  static const noShowBadgeOutlineColor = Color(0xFFF4C97A); //Color(0xFFFFF6E2)
  /// Booked / unavailable slot chip background.
  static const slotBookedBackgroundColor = Color(0xFF512324);
  static const darkNearbyColor = Color(0xFF222222);
  static const searchBackgroundColor = Color(0xFF23262D);
  static const iconGlassBackgroundColor = Color(0xFF4F5D6D);
  static const iconInnerColor = Color(0xFF4D4D52);
}

/// Surfaces and typography that follow [ThemeData.brightness], built from [AppColors] only.
class AppUiColors {
  const AppUiColors._(this._brightness);

  factory AppUiColors.of(BuildContext context) {
    return AppUiColors._(Theme.of(context).brightness);
  }

  final Brightness _brightness;

  bool get isLight => _brightness == Brightness.light;

  /// Client brand: primary icons/features (dark green in both light and dark mode).
  Color get brandPrimary => AppColors.primaryDarkColor;

  /// Client brand: secondary accent (light green in both light and dark mode).
  Color get brandSecondary => AppColors.primaryDarkColor;

  /// Dark green Pantone — same swatch in both themes (e.g. profile header).
  Color get brandDarkGreen => AppColors.primaryDarkColor;

  /// Light green Pantone — same swatch in both themes.
  Color get brandLightGreen => AppColors.primaryLightColor;

  Color get scaffoldBackground =>
      isLight ? AppColors.scaffoldColor : AppColors.darkScaffoldBackgroundColor;

  Color get cardBackground =>
      isLight ? AppColors.whiteColor : AppColors.darkScaffoldBackgroundColor; //AppColors.fieldBackgroundColor;

  Color get cardBookingBackground =>
      isLight ? AppColors.sandColor.withValues(alpha: 0.55): AppColors.fieldBackgroundBookingColor;

  Color get textPrimary =>
      isLight ? AppColors.blackColor : AppColors.whiteColor;

  Color get textSecondary =>
      isLight ? AppColors.greyColor : AppColors.iconsGreyColor;

  Color get textSecondaryWhite =>
      isLight ? AppColors.greyColor : AppColors.whiteColor;

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
      : AppColors.darkNearbyColor;

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

  /// Circular background behind each bottom nav icon.
  Color get bottomNavItemBg => isLight
      ? AppColors.blackColor.withValues(alpha: 0.04)
      : AppColors.whiteColor.withValues(alpha: 0.05);

  Color get borderMuted => isLight
      ? AppColors.hintColor
      : AppColors.greyBorderColor;

  Color get navInactive => isLight
      ? AppColors.greyColor
      : AppColors.whiteColor.withValues(alpha: 0.68);

  Color get navActive => brandPrimary;

  Color get chipInactiveBg =>
      isLight ? AppColors.whiteColor : AppColors.fieldBackgroundColor;

  Color get chipInactiveBg2 =>
      isLight ? AppColors.whiteColor : AppColors.whiteColor;

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

  Color get editButtonColor => isLight
      ? AppColors.whiteColor
      : AppColors.whiteColor.withValues(alpha: 0.16);

  Color get efficiencyTipBg => brandPrimary.withValues(alpha: isLight ? 0.1 : 0.2);

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

  Color get searchBackground =>
      isLight ? AppColors.whiteColor : AppColors.searchBackgroundColor;

  Color get iconGlassBackground =>
      isLight ? AppColors.whiteColor : AppColors.iconGlassBackgroundColor;

  Color get innerRowBg => isLight
      ? AppColors.sandColor.withValues(alpha: 0.55)
      : AppColors.searchBackgroundColor;

  Color get innerIconBg => isLight
      ? AppColors.sandColor.withValues(alpha: 0.55)
      : AppColors.iconInnerColor;

  Color get iconContainerOutline =>
      isLight ? AppColors.thumbBarGreyColor : AppColors.whiteColor;
}

import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

/// Light/dark palettes for revamped screens. Light values match the design specs.
class AppRevampedTheme {
  const AppRevampedTheme._(this._brightness);

  factory AppRevampedTheme.of(BuildContext context) {
    return AppRevampedTheme._(Theme.of(context).brightness);
  }

  final Brightness _brightness;

  bool get isLight => _brightness == Brightness.light;

  // ── Shared accents (brand stays readable in both modes) ─────────────────

  Color get brandGreen =>
      isLight ? const Color(0xFF006847) : const Color(0xFF00C48C);

  Color get brandGreenLight =>
      isLight ? const Color(0xFF00B386) : const Color(0xFF2DD4A8);

  Color get brandGreenBright =>
      isLight ? const Color(0xFF00A878) : const Color(0xFF34D399);

  Color get accentGreen =>
      isLight ? const Color(0xFF0E8F68) : const Color(0xFF14B87A);

  Color get scheduleLabelGreen =>
      isLight ? const Color(0xFF6EE7B7) : const Color(0xFF5EEAD4);

  Color get sessionActiveDot =>
      isLight ? const Color(0xFF6EE7B7) : const Color(0xFF34D399);

  Color get scaffoldBackground => isLight
      ? const Color(0xFFF8F9FB)
      : const Color(0xFF0F1412);

  Color get cardBackground =>
      isLight ? AppColors.whiteColor : const Color(0xFF1A211E);

  Color get elevatedCardBackground =>
      isLight ? AppColors.whiteColor : const Color(0xFF222A27);

  Color get subtleSurface => isLight
      ? const Color(0xFFF3F4F6)
      : const Color(0xFF252D2A);

  Color get chargerPortCardBackground => isLight
      ? const Color(0xFFF2F4F7)
      : const Color(0xFF252D2A);

  Color get durationCardBackground => isLight
      ? AppColors.shimmerGreyColor.withValues(alpha: 0.55)
      : const Color(0xFF1E2623);

  Color get textPrimary =>
      isLight ? const Color(0xFF1A1A1A) : AppColors.whiteColor;

  Color get textSecondary =>
      isLight ? const Color(0xFF757575) : const Color(0xFF9CA3AF);

  Color get textMuted =>
      isLight ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280);

  Color get textOnBrand => AppColors.whiteColor;

  Color get shadow =>
      isLight
          ? AppColors.blackColor.withValues(alpha: 0.05)
          : AppColors.blackColor.withValues(alpha: 0.35);

  Color get progressTrack => isLight
      ? AppColors.shimmerGreyColor
      : const Color(0xFF2A332F);

  Color get bottomTrack => isLight
      ? const Color(0xFFE0E3E6)
      : const Color(0xFF2A332F);

  Color get headerIconMuted => textMuted;

  Color get avatarBackground => isLight
      ? AppColors.shimmerGreyColor
      : const Color(0xFF2A332F);

  Color get stopRed => const Color(0xFFC62828);

  Color get takenPink =>
      isLight ? const Color(0xFFF9A8D4) : const Color(0xFF9D174D);

  Color get heldGreen => isLight
      ? const Color(0xFFD1FAE5)
      : const Color(0xFF1A3D32);

  Color get availableGreen => isLight
      ? const Color(0xFF047857)
      : const Color(0xFF34D399);

  Color get inUseBackground => isLight
      ? const Color(0xFFFEE2E2)
      : const Color(0xFF3D2020);

  Color get inUseText => isLight
      ? const Color(0xFFB91C1C)
      : const Color(0xFFF87171);

  Color get portPurpleBackground => isLight
      ? const Color(0xFFEDE9FE)
      : const Color(0xFF2E2640);

  Color get portPurpleText => isLight
      ? const Color(0xFF6D28D9)
      : const Color(0xFFC4B5FD);

  Color get mintBadgeBackground => isLight
      ? const Color(0xFFD1FAE5)
      : const Color(0xFF1A3328);

  Color get mintIconBackground => isLight
      ? const Color(0xFFE8F5E9)
      : const Color(0xFF1E2E28);

  Color get pricingCardBackground => isLight
      ? const Color(0xFFEEF2FF)
      : const Color(0xFF1E2438);

  Color get totalBoxBackground => subtleSurface;

  Color get topBarBackground => cardBackground;

  Color get mapCoverColor => const Color(0xFF0C4A4E);

  Color get mapHomeTextDark => isLight
      ? const Color(0xFF1B4332)
      : AppColors.whiteColor;

  Color get bottomSheetBackground => cardBackground;

  Color get indicatorInactive => progressTrack;

  Color get onboardingBackButtonBackground => isLight
      ? const Color(0xFFE8E6FF)
      : const Color(0xFF2A2838);

  Color get splashBackground => isLight
      ? const Color(0xFFEAF4EF)
      : const Color(0xFF0D1612);

  Color get splashGlowCenter => isLight
      ? AppColors.whiteColor.withValues(alpha: 0.92)
      : AppColors.whiteColor.withValues(alpha: 0.08);

  Color get splashGlowMid => isLight
      ? const Color(0xFFDDEBE5)
      : const Color(0xFF152820);

  Color get splashGlowOuter => splashBackground.withValues(alpha: 0);

  Color get splashTextPrimary =>
      isLight ? const Color(0xFF111111) : AppColors.whiteColor;

  Color get splashTextMuted => textSecondary;

  Color get splashBadgeGreenTop =>
      isLight ? const Color(0xFF16B07E) : const Color(0xFF14B87A);

  Color get splashBadgeGreenBottom =>
      isLight ? const Color(0xFF0A7354) : const Color(0xFF0D5C45);

  Color get onboardingBackgroundTop => isLight
      ? const Color(0xFFEAF6F2)
      : const Color(0xFF0D1814);

  Color get onboardingBackgroundBottom => isLight
      ? const Color(0xFFE8F0FA)
      : const Color(0xFF101820);

  Color get onboardingSkipText => textSecondary;

  Color get ecoGradientStart => isLight
      ? const Color(0xFF004D40)
      : const Color(0xFF003D32);

  Color get ecoGradientEnd => isLight
      ? const Color(0xFF006D44)
      : const Color(0xFF005544);

  Color get continueGradientStart => isLight
      ? const Color(0xFF004D40)
      : const Color(0xFF003D32);

  Color get continueGradientEnd => brandGreen;

  Color get paymentIconBlueBg => isLight
      ? const Color(0xFFE8F4FC)
      : const Color(0xFF1A2A38);

  Color get paymentIconRedBg => isLight
      ? const Color(0xFFFEE2E2)
      : const Color(0xFF3D2020);

  Color get paymentIconRed => isLight
      ? const Color(0xFFB91C1C)
      : const Color(0xFFF87171);

  Color get mapGridLine => AppColors.mapPinBlueColor.withValues(
        alpha: isLight ? 0.18 : 0.28,
      );

  Color get mapGridNode => AppColors.mapPinBlueColor.withValues(
        alpha: isLight ? 0.55 : 0.75,
      );

  Color get mapPlaceholderStart => isLight
      ? const Color(0xFF0B1220)
      : const Color(0xFF060A12);

  Color get mapPlaceholderEnd => isLight
      ? const Color(0xFF111827)
      : const Color(0xFF0C1219);

  Color get selectedSlotBackground => brandGreen;

  Color get selectedSlotBorder => isLight
      ? const Color(0xFF004D40)
      : const Color(0xFF003D32);

  Color get selectedSlotText => isLight
      ? const Color(0xFF1A1A1A)
      : AppColors.whiteColor;

  Color get availableSlotBorder => brandGreen.withValues(alpha: 0.45);

  Color get disabledButtonGrey => AppColors.thumbBarGreyColor;

  Color get sliderThumbBorder => AppColors.blackColor;

  Color get fabLayersBackground => cardBackground;

  Color get fabLayersIcon => textPrimary;

  Color get subtitleDivider => textSecondary;

  Color get stationCardSelectedBg =>
      mintIconBackground.withValues(alpha: isLight ? 0.55 : 0.45);

  Color get stationCardBorder => isLight
      ? AppColors.colorsOutlineColor.withValues(alpha: 0.7)
      : AppColors.whiteColor.withValues(alpha: 0.08);

  Color get stationCardSelectedBorder =>
      brandGreen.withValues(alpha: 0.35);

  Color get filterChipBackground => progressTrack;

  Color get portIndicatorActiveBg =>
      brandGreenBright.withValues(alpha: isLight ? 0.18 : 0.28);

  Color get heroMetaPillBackground => isLight
      ? AppColors.whiteColor.withValues(alpha: 0.94)
      : AppColors.whiteColor.withValues(alpha: 0.12);

  // ── Screen-specific light values (dark uses brighter accents) ───────────

  Color get stationDetailBackground => isLight
      ? const Color(0xFFFFFFFF)
      : const Color(0xFF0F1412);

  Color get stationDetailBrandGreen => isLight
      ? const Color(0xFF00796B)
      : const Color(0xFF00BFA5);

  Color get stationDetailBrandGreenLight => isLight
      ? const Color(0xFF00BFA5)
      : const Color(0xFF5EEAD4);

  Color get bookSlotPrimaryGreen => isLight
      ? const Color(0xFF00C48C)
      : const Color(0xFF2DD4A8);

  Color get bookSlotDarkGreen => isLight
      ? const Color(0xFF004D40)
      : const Color(0xFF003D32);

  Color get paymentPrimaryGreen => isLight
      ? const Color(0xFF006B4D)
      : const Color(0xFF00C48C);

  Color get chargingStatusPrimaryGreen => isLight
      ? const Color(0xFF006D44)
      : const Color(0xFF00C48C);

  Color get splashBrandGreen => isLight
      ? const Color(0xFF0E8F68)
      : const Color(0xFF14B87A);

  Color get datePillUnselectedShadow => isLight
      ? AppColors.blackColor.withValues(alpha: 0.04)
      : AppColors.transparentColor;

  Color get datePillSelectedShadow => brandGreen.withValues(
        alpha: isLight ? 0.25 : 0.4,
      );
}

extension AppRevampedThemeContext on BuildContext {
  AppRevampedTheme get revampedTheme => AppRevampedTheme.of(this);
}

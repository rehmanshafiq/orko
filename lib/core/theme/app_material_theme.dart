import 'package:flutter/material.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

/// Material [ThemeData] for the app (aligned with [AppColors] brand green).
abstract final class AppMaterialTheme {
  static ThemeData get light => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppColors.scaffoldColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryDarkColor,
          brightness: Brightness.light,
          primary: AppColors.primaryDarkColor,
          secondary: AppColors.primaryLightColor,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.shimmerGreyColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );

  static ThemeData get dark => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkScaffoldBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primaryDarkColor,
          brightness: Brightness.dark,
          primary: AppColors.primaryDarkColor,
          secondary: AppColors.primaryLightColor,
        ),
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
        snackBarTheme: const SnackBarThemeData(
          contentTextStyle: TextStyle(color: Colors.white),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.fieldBackgroundColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
}

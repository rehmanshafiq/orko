import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';

/// Common helper methods used across the app.
class AppHelpers {
  AppHelpers._();

  /// Thousands-separated amount with up to one decimal place — the decimal is
  /// dropped when it's `.0`, so `1622.5` → `1,622.5` and `1500.0` → `1,500`.
  static final NumberFormat _amountFormat = NumberFormat('#,##0.#');

  /// Formats a monetary [amount] as `PKR 1,622.5` — comma-grouped with one
  /// decimal place, trimming a trailing `.0` (e.g. `PKR 1,500`). Pass
  /// [currency] to override the default `PKR` prefix.
  static String formatCurrency(num amount, {String currency = 'PKR'}) {
    return '$currency ${_amountFormat.format(amount)}';
  }

  /// Whole-number, comma-grouped amount (e.g. `1456` → `1,456`).
  static final NumberFormat _wholeAmountFormat = NumberFormat('#,##0');

  /// Formats a monetary [amount] as `Rs. 1,456` — comma-grouped, no decimals.
  /// Used across the trip-planner flow for a consistent currency style.
  static String formatRs(num amount) =>
      'Rs. ${_wholeAmountFormat.format(amount)}';

  /// Shows a snackbar with the given message.
  static void showSnackBar(BuildContext context, String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.removeColor : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  /// Simple email validation.
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  /// Simple password validation.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  /// Formats station `distance` from the nearby-stations API (kilometers).
  static String formatDistanceKm(double km) {
    if (km <= 0) return '—';
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }
}

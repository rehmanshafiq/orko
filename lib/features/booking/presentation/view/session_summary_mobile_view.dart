import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/helpers.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_detail_entity.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/session_summary_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/session_summary_state.dart';

/// Summary of a finished charging session: energy dispensed, carbon offset,
/// session duration, and the amount charged. Every figure renders defensively
/// ('—' fallbacks) since the backend substitutes "N/A" while data is missing.
class SessionSummaryMobileView extends StatelessWidget {
  const SessionSummaryMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<SessionSummaryCubit, SessionSummaryState>(
          builder: (context, state) {
            if (state.isLoading) {
              return Center(
                child: SizedBox(
                  width: 28.w,
                  height: 28.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: ui.brandPrimary,
                  ),
                ),
              );
            }
            if (state.isFailure || state.detail == null) {
              return _FailureBody(ui: ui, error: state.error);
            }
            return _SummaryBody(ui: ui, detail: state.detail!);
          },
        ),
      ),
    );
  }
}

class _FailureBody extends StatelessWidget {
  const _FailureBody({required this.ui, required this.error});

  final AppUiColors ui;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppUtils.horizontal16Padding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Icon(Icons.error_outline_rounded,
              color: ui.textSecondary, size: 40.sp),
          12.verticalSpace,
          AppText(
            error ?? 'Could not load your session summary.',
            textAlign: TextAlign.center,
            color: ui.textSecondary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight500,
          ),
          20.verticalSpace,
          PrimaryButtonWidget(
            text: 'Retry',
            onPress: () => context.read<SessionSummaryCubit>().load(),
            buttonHeight: 44.h,
            cornerRadius: 24.r,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight700,
          ),
          10.verticalSpace,
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: AppText(
              'Close',
              color: ui.textSecondary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight600,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.ui, required this.detail});

  final AppUiColors ui;
  final ChargeSessionDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: Icon(
                Icons.close_rounded,
                color: ui.textSecondary,
                size: 24.r,
              ),
              padding: EdgeInsets.all(8.r),
              constraints: BoxConstraints(minWidth: 40.w, minHeight: 40.h),
            ),
          ),
        ),
        Expanded(
          child: ListView(
            padding: AppUtils.horizontal16Padding,
            children: [
              8.verticalSpace,
              Icon(
                Icons.check_circle_rounded,
                color: ui.brandPrimary,
                size: 56.sp,
              ),
              12.verticalSpace,
              AppText(
                'Charging Complete',
                textAlign: TextAlign.center,
                color: ui.textPrimary,
                fontSize: FontSizes.font20Sp,
                fontWeight: FontWeights.weight700,
              ),
              6.verticalSpace,
              AppText(
                _subtitle,
                textAlign: TextAlign.center,
                color: ui.textSecondary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight500,
              ),
              16.verticalSpace,
              _PaymentButtons(ui: ui),
              20.verticalSpace,
              _StatCard(
                ui: ui,
                icon: Icons.bolt_rounded,
                iconColor: AppColors.mapPinBlueColor,
                title: 'Total Energy Dispensed',
                value: detail.energyConsumed != null
                    ? detail.energyConsumed!.toStringAsFixed(2)
                    : '—',
                unit: detail.energyConsumed != null ? 'kWh' : '',
                subtitle: 'Energy Delivered during session',
              ),
              12.verticalSpace,
              _StatCard(
                ui: ui,
                icon: Icons.eco_rounded,
                iconColor: ui.brandPrimary,
                title: 'Carbon Offset',
                value: detail.co2ReducedKg != null
                    ? _trimDouble(detail.co2ReducedKg!)
                    : '—',
                unit: detail.co2ReducedKg != null ? 'kg' : '',
                subtitle: 'CO₂ emissions saved',
              ),
              12.verticalSpace,
              _StatCard(
                ui: ui,
                icon: Icons.offline_bolt_rounded,
                iconColor: AppColors.ratingStarColor,
                title: 'Charging Time',
                value: detail.duration ?? '—',
                unit: '',
                subtitle: 'Total session duration',
              ),
              16.verticalSpace,
              _AmountCard(ui: ui, detail: detail),
              24.verticalSpace,
            ],
          ),
        ),
        Padding(
          padding: AppUtils.horizontal16Padding.add(
            EdgeInsets.only(bottom: 12.h, top: 8.h),
          ),
          child: PrimaryButtonWidget(
            text: 'Done',
            onPress: () => Navigator.of(context).maybePop(),
            buttonHeight: 44.h,
            cornerRadius: 24.r,
            gradientColors: const [
              AppColors.primaryDarkColor,
              AppColors.primaryDarkButtonColor,
            ],
            textColor: AppColors.whiteColor,
            fontSize: FontSizes.font15Sp,
            fontWeight: FontWeights.weight700,
          ),
        ),
      ],
    );
  }

  /// "Dolmen Mall Clifton · 16/07/2026 · 2:47 PM" — parts drop out when
  /// unavailable.
  String get _subtitle {
    final parts = <String>[detail.displayName];
    final completed = _formatTimestamp(detail.completedAt);
    if (completed != null) parts.add(completed);
    return parts.join(' · ');
  }

  static String? _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy · h:mm a').format(parsed);
  }

  /// Drops a trailing `.0` so `12.75` stays but `80.0` shows as `80`.
  static String _trimDouble(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

/// Payment choice for the finished session: in-app (not live yet — shows a
/// "Coming soon" toast) or at the station.
class _PaymentButtons extends StatelessWidget {
  const _PaymentButtons({required this.ui});

  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButtonWidget(
            text: 'Pay at Station',
            onPress: _onPayAtStation,
            buttonHeight: 42.h,
            cornerRadius: 24.r,
            gradientColors: const [
              AppColors.primaryDarkColor,
              AppColors.primaryDarkButtonColor,
            ],
            textColor: AppColors.whiteColor,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight600,
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: PrimaryButtonWidget(
            text: 'Pay in App',
            onPress: _onPayInApp,
            buttonHeight: 42.h,
            cornerRadius: 24.r,
            strokeColor: ui.brandPrimary,
            buttonColor: AppColors.transparentColor,
            textColor: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight600,
          ),
        ),
      ],
    );
  }

  /// In-app payment isn't live yet.
  void _onPayInApp() {
    Fluttertoast.showToast(
      msg: 'Coming soon',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }

  void _onPayAtStation() {
    Fluttertoast.showToast(
      msg: 'Please pay at the station counter',
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
    );
  }
}

/// One summary stat: icon + title on top, big value, muted subtitle — mirrors
/// the stat-card layout of the session-summary design.
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.ui,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.unit,
    required this.subtitle,
  });

  final AppUiColors ui;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String unit;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20.sp),
              8.horizontalSpace,
              Expanded(
                child: AppText(
                  title,
                  color: ui.textPrimary,
                  fontSize: FontSizes.font14Sp,
                  fontWeight: FontWeights.weight700,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          10.verticalSpace,
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              AppText(
                value,
                color: ui.textPrimary,
                fontSize: FontSizes.font22Sp,
                fontWeight: FontWeights.weight700,
              ),
              if (unit.isNotEmpty) ...[
                6.horizontalSpace,
                Padding(
                  padding: EdgeInsets.only(bottom: 2.h),
                  child: AppText(
                    unit,
                    color: ui.textSecondary,
                    fontSize: FontSizes.font15Sp,
                    fontWeight: FontWeights.weight600,
                  ),
                ),
              ],
            ],
          ),
          6.verticalSpace,
          AppText(
            subtitle,
            color: ui.textSecondary,
            fontSize: FontSizes.font12Sp,
            fontWeight: FontWeights.weight500,
          ),
        ],
      ),
    );
  }
}

/// Cost breakdown: energy + tax rows, divider, then the total amount.
class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.ui, required this.detail});

  final AppUiColors ui;
  final ChargeSessionDetailEntity detail;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppUtils.all18Padding,
      decoration: BoxDecoration(
        color: ui.cardBackground,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: ui.borderSubtle),
      ),
      child: Column(
        children: [
          _row('Energy Cost', detail.energyCost),
          8.verticalSpace,
          _row('Tax', detail.taxCost),
          12.verticalSpace,
          Divider(height: 1, color: ui.dividerLine),
          12.verticalSpace,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                'Total Amount',
                color: ui.textPrimary,
                fontSize: FontSizes.font15Sp,
                fontWeight: FontWeights.weight700,
              ),
              AppText(
                _formatAmount(detail.totalCost),
                color: ui.brandPrimary,
                fontSize: FontSizes.font18Sp,
                fontWeight: FontWeights.weight700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _row(String label, double? amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        AppText(
          label,
          color: ui.textSecondary,
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight500,
        ),
        AppText(
          _formatAmount(amount),
          color: ui.textPrimary,
          fontSize: FontSizes.font13Sp,
          fontWeight: FontWeights.weight600,
        ),
      ],
    );
  }

  String _formatAmount(double? amount) =>
      amount != null ? AppHelpers.formatCurrency(amount) : '—';
}

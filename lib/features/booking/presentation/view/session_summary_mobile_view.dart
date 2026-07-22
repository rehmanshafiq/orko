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
import 'package:orko_hubco/features/booking/presentation/widgets/download_receipt_button.dart';

/// Summary of a finished charging session: energy dispensed, carbon offset,
/// session duration, and the amount charged. Every figure renders defensively
/// ('—' fallbacks) since the backend substitutes "N/A" while data is missing.
class SessionSummaryMobileView extends StatelessWidget {
  const SessionSummaryMobileView({super.key, this.showPaymentButtons = true});

  /// Whether the pay-at-station / pay-in-app buttons are shown. Hidden when the
  /// summary is opened from the History tab (a past session — nothing to pay).
  final bool showPaymentButtons;

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
            return _SummaryBody(
              ui: ui,
              detail: state.detail!,
              showPaymentButtons: showPaymentButtons,
            );
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

class _SummaryBody extends StatefulWidget {
  const _SummaryBody({
    required this.ui,
    required this.detail,
    required this.showPaymentButtons,
  });

  final AppUiColors ui;
  final ChargeSessionDetailEntity detail;
  final bool showPaymentButtons;

  @override
  State<_SummaryBody> createState() => _SummaryBodyState();
}

class _SummaryBodyState extends State<_SummaryBody> {
  /// Set once the user completes the Pay-at-Station flow. Then the close icon
  /// appears, the payment buttons lock (disabled/greyed), and the download
  /// receipt button shows at the bottom.
  bool _paidAtStation = false;
  _StationPaymentMethod? _method;

  /// The close icon is hidden on the live-session flow until the user has paid
  /// at the station; on other flows (History) it's always available.
  bool get _showCloseIcon => !widget.showPaymentButtons || _paidAtStation;

  void _onPaidAtStation(_StationPaymentMethod method) {
    if (_paidAtStation) return;
    setState(() {
      _paidAtStation = true;
      _method = method;
    });
  }

  @override
  Widget build(BuildContext context) {
    final ui = widget.ui;
    final detail = widget.detail;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(8.w, 4.h, 8.w, 0),
          child: Align(
            alignment: Alignment.centerRight,
            child: _showCloseIcon
                ? IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: ui.textSecondary,
                      size: 24.r,
                    ),
                    padding: EdgeInsets.all(8.r),
                    constraints:
                        BoxConstraints(minWidth: 40.w, minHeight: 40.h),
                  )
                : SizedBox(width: 40.w, height: 40.h),
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
              if (widget.showPaymentButtons) ...[
                16.verticalSpace,
                _PaymentButtons(
                  ui: ui,
                  disabled: _paidAtStation,
                  onPaidAtStation: _onPaidAtStation,
                ),
              ],
              20.verticalSpace,
              _StatCard(
                ui: ui,
                icon: Icons.bolt_rounded,
                iconColor: ui.brandPrimary,
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
                iconColor: ui.brandPrimary,
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
        // The receipt is always available from History (a past, settled
        // session); on the live-session flow it appears once paid at station.
        if (_paidAtStation || !widget.showPaymentButtons)
          Padding(
            padding: AppUtils.horizontal16Padding.add(
              EdgeInsets.only(bottom: 12.h, top: 8.h),
            ),
            child: DownloadReceiptButton(
              bookingRef: '#${detail.id}',
              stationName: detail.displayName,
              slotLabel: _receiptSlotLabel,
              paymentLabel: _paymentLabel,
              amountPaid: _amountPaid,
            ),
          ),
        // Padding(
        //   padding: AppUtils.horizontal16Padding.add(
        //     EdgeInsets.only(bottom: 12.h, top: 8.h),
        //   ),
        //   child: PrimaryButtonWidget(
        //     text: 'Done',
        //     onPress: () => Navigator.of(context).maybePop(),
        //     buttonHeight: 44.h,
        //     cornerRadius: 24.r,
        //     gradientColors: const [
        //       AppColors.primaryDarkColor,
        //       AppColors.primaryDarkButtonColor,
        //     ],
        //     textColor: AppColors.whiteColor,
        //     fontSize: FontSizes.font15Sp,
        //     fontWeight: FontWeights.weight700,
        //   ),
        // ),
      ],
    );
  }

  /// "Dolmen Mall Clifton · 16/07/2026 · 2:47 PM" — parts drop out when
  /// unavailable.
  String get _subtitle {
    final parts = <String>[widget.detail.displayName];
    final completed = _formatTimestamp(widget.detail.completedAt);
    if (completed != null) parts.add(completed);
    return parts.join(' · ');
  }

  /// Date/time label used on the receipt for this session.
  String get _receiptSlotLabel =>
      _formatTimestamp(widget.detail.completedAt) ??
      widget.detail.duration ??
      '—';

  /// Human-readable payment method for the receipt. Null when no method was
  /// chosen (e.g. opened from History), which hides the row on the receipt.
  String? get _paymentLabel {
    switch (_method) {
      case _StationPaymentMethod.cash:
        return 'Cash';
      case _StationPaymentMethod.credit:
        return 'Credit/Debit';
      case null:
        return null;
    }
  }

  /// Amount owed for the session, rounded to a whole number.
  int get _amountPaid =>
      (widget.detail.totalCost ?? widget.detail.energyCost ?? 0).round();

  static String? _formatTimestamp(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
    if (parsed == null) return raw;
    return DateFormat('dd/MM/yyyy').format(parsed);
  }

  /// Drops a trailing `.0` so `12.75` stays but `80.0` shows as `80`.
  static String _trimDouble(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toStringAsFixed(2);
  }
}

/// How the user wants to settle at the station, picked from the bottom sheet.
enum _StationPaymentMethod { cash, credit }

/// Payment choice for the finished session: in-app (not live yet — shows a
/// "Coming soon" toast) or at the station (opens a cash/credit picker).
class _PaymentButtons extends StatelessWidget {
  const _PaymentButtons({
    required this.ui,
    this.disabled = false,
    required this.onPaidAtStation,
  });

  final AppUiColors ui;

  /// When true both buttons are locked (disabled/greyed) — set after the user
  /// has completed the pay-at-station flow.
  final bool disabled;

  /// Called with the chosen method once the user settles at the station.
  final ValueChanged<_StationPaymentMethod> onPaidAtStation;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButtonWidget(
            text: 'Pay at Station',
            onPress: disabled ? null : () => _onPayAtStation(context),
            isEnabled: !disabled,
            buttonHeight: 42.h,
            cornerRadius: 24.r,
            strokeColor: ui.textMuted,
            buttonColor: ui.isLight ? AppColors.shimmerGreyColor : AppColors.transparentColor,
            textColor: ui.textPrimary,
            fontSize: FontSizes.font14Sp,
            fontWeight: FontWeights.weight600,
          ),
        ),
        12.horizontalSpace,
        Expanded(
          child: PrimaryButtonWidget(
            text: 'Pay in App',
            onPress: disabled ? null : _onPayInApp,
            isEnabled: !disabled,
            buttonHeight: 42.h,
            cornerRadius: 24.r,
            strokeColor: ui.textMuted,
            buttonColor: ui.isLight ? AppColors.shimmerGreyColor : AppColors.transparentColor,
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
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 4,
    );
  }

  /// Lets the user pick how they'll settle at the station, then confirms the
  /// choice with a toast. Dismissing the sheet without picking does nothing.
  Future<void> _onPayAtStation(BuildContext context) async {
    final method = await showModalBottomSheet<_StationPaymentMethod>(
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
              12.verticalSpace,
              AppText(
                'Pay at Station',
                color: ui.textPrimary,
                fontSize: FontSizes.font16Sp,
                fontWeight: FontWeights.weight700,
              ),
              4.verticalSpace,
              AppText(
                'How would you like to pay?',
                color: ui.textSecondary,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight500,
              ),
              8.verticalSpace,
              _PaymentMethodTile(
                ui: ui,
                icon: Icons.payments_outlined,
                label: 'Cash',
                onTap: () => Navigator.of(sheetContext)
                    .pop(_StationPaymentMethod.cash),
              ),
              _PaymentMethodTile(
                ui: ui,
                icon: Icons.credit_card_rounded,
                label: 'Credit/Debit Card',
                onTap: () => Navigator.of(sheetContext)
                    .pop(_StationPaymentMethod.credit),
              ),
              8.verticalSpace,
            ],
          ),
        );
      },
    );
    if (method == null) return;

    Fluttertoast.showToast(
      msg: method == _StationPaymentMethod.cash
          ? 'Please pay in cash at the station counter'
          : 'Please pay by credit card at the station counter',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 4,
    );
    onPaidAtStation(method);
  }
}

/// One tappable row of the pay-at-station sheet (icon + label).
class _PaymentMethodTile extends StatelessWidget {
  const _PaymentMethodTile({
    required this.ui,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final AppUiColors ui;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: ui.brandPrimary, size: 22.sp),
      title: AppText(
        label,
        color: ui.textPrimary,
        fontSize: FontSizes.font15Sp,
        fontWeight: FontWeights.weight600,
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        color: ui.textSecondary,
        size: 22.sp,
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w),
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

/// Cost breakdown: the session's total cost.
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
          _row('Total Cost', detail.totalCost),
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
          color: ui.textPrimary,
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
      amount != null ? AppHelpers.formatCurrency(amount.roundToDouble()) : '—';
}

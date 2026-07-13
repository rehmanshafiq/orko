import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/core/utils/widgets/primary_button_widget.dart';
import 'package:orko_hubco/features/booking/domain/entities/charge_session_history_entity.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_state.dart';
import 'package:orko_hubco/features/booking/presentation/mobile/charging_session_receipt_mobile_view.dart';
import 'package:orko_hubco/features/profile/presentation/widgets/section_card.dart';

/// Charging-history section rendered as a desktop file-manager "list/details"
/// view: a leading icon per row followed by column-aligned fields (Name, Date,
/// Duration, Energy, Status, Amount) under a sticky column header. The table is
/// horizontally scrollable so the columns stay readable on narrow phones.
///
/// Reuses the same charge-session-history data as the My Bookings → History tab
/// (via [MyBookingsCubit]) and handles every edge case: first-load spinner,
/// failure + retry, guest / empty state, and in-progress rows with no
/// energy/cost yet. Collapsed by default; tap the header to expand.
class HistorySection extends StatefulWidget {
  const HistorySection({super.key});

  @override
  State<HistorySection> createState() => _HistorySectionState();
}

class _HistorySectionState extends State<HistorySection> {
  bool _expanded = false;

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return SectionCard(
      child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
        builder: (context, state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _HistoryHeader(
                ui: ui,
                state: state,
                expanded: _expanded,
                onTap: _toggle,
              ),
              AnimatedCrossFade(
                firstChild: const SizedBox(width: double.infinity),
                secondChild: Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: _HistoryBody(ui: ui, state: state),
                ),
                crossFadeState: _expanded
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 200),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HistoryHeader extends StatelessWidget {
  const _HistoryHeader({
    required this.ui,
    required this.state,
    required this.expanded,
    required this.onTap,
  });

  final AppUiColors ui;
  final MyBookingsState state;
  final bool expanded;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final count = state.historySessions.length;
    final showCount =
        state.historyStatus == MyBookingsStatus.success && count > 0;
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(Icons.history_rounded, color: ui.brandPrimary, size: 22.r),
          8.horizontalSpace,
          Expanded(
            child: AppText(
              'Charging History',
              color: ui.textPrimary,
              fontSize: FontSizes.font16Sp,
              fontWeight: FontWeights.weight700,
            ),
          ),
          if (showCount) ...[
            AppText(
              count == 1 ? '1 session' : '$count sessions',
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight500,
            ),
            4.horizontalSpace,
          ],
          AnimatedRotation(
            turns: expanded ? 0.5 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: ui.textSecondary,
              size: 24.r,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryBody extends StatelessWidget {
  const _HistoryBody({required this.ui, required this.state});

  final AppUiColors ui;
  final MyBookingsState state;

  @override
  Widget build(BuildContext context) {
    // First-ever load (or a spinner-triggered reload): show the loader.
    if (state.historyStatus == MyBookingsStatus.loading ||
        state.historyStatus == MyBookingsStatus.initial) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 24.h),
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
    }

    if (state.historyStatus == MyBookingsStatus.failure) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 16.h),
        child: Column(
          children: [
            Icon(Icons.error_outline_rounded,
                color: ui.textSecondary, size: 34.sp),
            10.verticalSpace,
            AppText(
              state.historyError ?? 'Could not load your charging history.',
              textAlign: TextAlign.center,
              color: ui.textSecondary,
              fontSize: FontSizes.font13Sp,
              fontWeight: FontWeights.weight500,
            ),
            14.verticalSpace,
            SizedBox(
              width: 150.w,
              child: PrimaryButtonWidget(
                text: 'Retry',
                onPress: () => context.read<MyBookingsCubit>().loadHistory(),
                buttonHeight: 38.h,
                cornerRadius: 22.r,
                buttonColor: ui.brandPrimary,
                textColor: AppColors.whiteColor,
                fontSize: FontSizes.font13Sp,
                fontWeight: FontWeights.weight700,
              ),
            ),
          ],
        ),
      );
    }

    final sessions = state.historySessions;
    if (sessions.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: 18.h),
        child: Column(
          children: [
            Icon(Icons.folder_open_rounded,
                color: ui.textSecondary, size: 38.sp),
            10.verticalSpace,
            AppText(
              'No History',
              color: ui.textPrimary,
              fontSize: FontSizes.font14Sp,
              fontWeight: FontWeights.weight700,
            ),
            4.verticalSpace,
            AppText(
              'Your charging sessions will appear here.',
              textAlign: TextAlign.center,
              color: ui.textSecondary,
              fontSize: FontSizes.font12Sp,
              fontWeight: FontWeights.weight400,
            ),
          ],
        ),
      );
    }

    return _HistoryTable(ui: ui, sessions: sessions);
  }
}

/// File-manager style "details" list: a column-header row over icon + column
/// data rows, wrapped in a horizontal scroll view so the fixed-width columns
/// never overflow on small screens.
class _HistoryTable extends StatelessWidget {
  const _HistoryTable({required this.ui, required this.sessions});

  final AppUiColors ui;
  final List<ChargeSessionHistoryEntity> sessions;

  @override
  Widget build(BuildContext context) {
    // Grab the available (card-inner) width first, then bound the scrolling
    // table to at least that width so the Divider/ListView have a finite width
    // to stretch into (a bare horizontal ScrollView would give them unbounded
    // constraints and throw).
    return LayoutBuilder(
      builder: (context, constraints) {
        final tableWidth = constraints.maxWidth > _HistoryColumns.totalWidth
            ? constraints.maxWidth
            : _HistoryColumns.totalWidth;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: SizedBox(
            width: tableWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _HistoryColumnHeader(ui: ui),
                Divider(height: 1, thickness: 1, color: ui.borderSubtle),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: sessions.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, thickness: 1, color: ui.borderSubtle),
                  itemBuilder: (context, index) =>
                      _HistoryRow(ui: ui, session: sessions[index]),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Fixed pixel widths for every column, so the header and data rows stay
/// aligned inside the horizontal scroll view.
class _HistoryColumns {
  static double get icon => 44.r;

  /// First column stacks the station name, date and price together.
  static double get info => 180.w;
  static double get duration => 96.w;
  static double get energy => 84.w;
  static double get status => 104.w;

  static double get gap => 12.w;

  static double get totalWidth =>
      icon + info + duration + energy + status + gap * 4;
}

class _HistoryColumnHeader extends StatelessWidget {
  const _HistoryColumnHeader({required this.ui});

  final AppUiColors ui;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4.h),
      child: Row(
        children: [
          SizedBox(width: _HistoryColumns.icon),
          SizedBox(width: _HistoryColumns.gap),
          SizedBox(width: _HistoryColumns.info),
          SizedBox(width: _HistoryColumns.gap),
          SizedBox(width: _HistoryColumns.duration),
          SizedBox(width: _HistoryColumns.gap),
          _HistoryHeaderCell(ui: ui, label: 'Energy', width: _HistoryColumns.energy),
          SizedBox(width: _HistoryColumns.gap),
          _HistoryHeaderCell(ui: ui, label: 'Status', width: _HistoryColumns.status),
        ],
      ),
    );
  }
}

class _HistoryHeaderCell extends StatelessWidget {
  const _HistoryHeaderCell({
    required this.ui,
    required this.label,
    required this.width,
  });

  final AppUiColors ui;
  final String label;
  final double width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppText(
        label,
        color: ui.textSecondary,
        fontSize: FontSizes.font11Sp,
        fontWeight: FontWeights.weight700,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.ui, required this.session});

  final AppUiColors ui;
  final ChargeSessionHistoryEntity session;

  @override
  Widget build(BuildContext context) {
    final isInProgress = session.isInProgress;
    final dateLabel = _formatHistoryStartedAt(session.startedAt);
    final durationLabel = (session.duration != null &&
            session.duration!.trim().isNotEmpty)
        ? session.duration!.trim()
        : (isInProgress ? 'In progress' : '—');
    final energyLabel = session.energyConsumed != null
        ? '${_trimHistoryNum(session.energyConsumed!)} kWh'
        : '—';
    final amountLabel = session.totalCost != null
        ? _formatHistoryAmount(session.totalCost!)
        : '—';
    final statusLabel = session.status.trim().isNotEmpty
        ? session.status.trim()
        : (isInProgress ? 'In progress' : 'Unknown');

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openSessionReceipt(context, session),
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 12.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: _HistoryColumns.icon,
                child: Container(
                  height: 34.r,
                  width: 34.r,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: ui.isLight
                          ? ui.iconContainerOutline
                          : ui.brandPrimary,
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    Icons.bolt,
                    color: ui.brandPrimary,
                    size: 18.sp,
                  ),
                ),
              ),
              SizedBox(width: _HistoryColumns.gap),
              SizedBox(
                width: _HistoryColumns.info,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText(
                      session.displayName,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font13Sp,
                      fontWeight: FontWeights.weight600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    2.verticalSpace,
                    AppText(
                      dateLabel,
                      color: ui.textSecondary,
                      fontSize: FontSizes.font12Sp,
                      fontWeight: FontWeights.weight400,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    4.verticalSpace,
                    AppText(
                      amountLabel,
                      color: ui.textPrimary,
                      fontSize: FontSizes.font13Sp,
                      fontWeight: FontWeights.weight700,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: _HistoryColumns.gap),
              _HistoryRowCell(
                width: _HistoryColumns.duration,
                value: durationLabel,
                color: ui.textSecondary,
              ),
              SizedBox(width: _HistoryColumns.gap),
              _HistoryRowCell(
                width: _HistoryColumns.energy,
                value: energyLabel,
                color: energyLabel == '—' ? ui.textSecondary : ui.brandPrimary,
                fontWeight: FontWeights.weight600,
              ),
              SizedBox(width: _HistoryColumns.gap),
              SizedBox(
                width: _HistoryColumns.status,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _HistoryStatusBadge(
                    ui: ui,
                    label: statusLabel,
                    isInProgress: isInProgress,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryRowCell extends StatelessWidget {
  const _HistoryRowCell({
    required this.width,
    required this.value,
    required this.color,
    this.fontWeight,
  });

  final double width;
  final String value;
  final Color color;
  final FontWeight? fontWeight;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: AppText(
        value,
        color: color,
        fontSize: FontSizes.font12Sp,
        fontWeight: fontWeight ?? FontWeights.weight400,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _HistoryStatusBadge extends StatelessWidget {
  const _HistoryStatusBadge({
    required this.ui,
    required this.label,
    required this.isInProgress,
  });

  final AppUiColors ui;
  final String label;
  final bool isInProgress;

  @override
  Widget build(BuildContext context) {
    final accent = isInProgress ? ui.brandPrimary : ui.brandSecondary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(width: 1.w, color: accent),
      ),
      child: AppText(
        label,
        color: ui.textSecondary,
        fontSize: FontSizes.font11Sp,
        fontWeight: FontWeights.weight600,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

/// Opens the charging-session receipt screen. In-progress sessions have no
/// final cost yet, so we surface a snackbar instead of a partial receipt.
void _openSessionReceipt(
  BuildContext context,
  ChargeSessionHistoryEntity session,
) {
  if (session.isInProgress) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Receipt is available once your session is completed.'),
      ),
    );
    return;
  }

  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ChargingSessionReceiptMobileView(session: session),
    ),
  );
}

/// Formats a `yyyy-MM-dd HH:mm:ss` timestamp into `MMM d, yyyy · h:mm a`,
/// falling back to the raw string (or a placeholder) when it can't be parsed.
String _formatHistoryStartedAt(String? raw) {
  if (raw == null || raw.isEmpty) return 'Date unavailable';
  final parsed = DateTime.tryParse(raw.replaceFirst(' ', 'T'));
  if (parsed == null) return raw;
  return DateFormat('MMM d, yyyy · h:mm a').format(parsed);
}

/// Drops a trailing `.0` so `0.45` stays but `12.0` shows as `12`.
String _trimHistoryNum(double value) {
  if (value == value.roundToDouble()) return value.toInt().toString();
  return value.toString();
}

/// Formats a monetary amount as `PKR 1,622.5` with comma-separated thousands,
/// matching the stats grid style on this screen.
String _formatHistoryAmount(double amount) {
  final neg = amount < 0;
  final abs = amount.abs();

  if (abs == abs.roundToDouble()) {
    return 'PKR ${_groupHistoryNum(abs.round(), neg: neg)}';
  }

  final fixed = abs.toStringAsFixed(1);
  final dotIndex = fixed.indexOf('.');
  final whole = _groupHistoryNum(int.parse(fixed.substring(0, dotIndex)));
  final frac = fixed.substring(dotIndex + 1);
  if (frac == '0') return 'PKR ${neg ? '-$whole' : whole}';
  return 'PKR ${neg ? '-$whole.$frac' : '$whole.$frac'}';
}

/// Groups an integer with thousands separators (5930 → "5,930").
String _groupHistoryNum(int v, {bool neg = false}) {
  final s = v.abs().toString();
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i != 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  final grouped = buf.toString();
  return neg ? '-$grouped' : grouped;
}

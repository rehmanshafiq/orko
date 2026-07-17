import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/utils/app_storage/app_storage.dart';
import 'package:orko_hubco/core/utils/responsive_view_widget.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/session_summary_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/view/session_summary_mobile_view.dart';

/// Post-session summary shown once a live charging session finishes: energy
/// dispensed, CO2 offset, session duration, and the amount charged.
class SessionSummaryPage extends StatelessWidget {
  const SessionSummaryPage({super.key, required this.sessionId});

  final int sessionId;

  /// Latched while a summary route is on screen, so the bookings Active tab
  /// and the charging-status screen (which can both detect the same session
  /// completion) can't push two copies on top of each other.
  static bool _isShowing = false;

  /// Shows the summary for [sessionId] over the root navigator (above the
  /// bottom-nav shell) exactly once, and clears the persisted session id when
  /// it's dismissed — no matter how the fetch inside went. Safe to call from
  /// concurrent detection sites; extra calls while one is up are no-ops.
  static Future<void> show(
    BuildContext context, {
    required int sessionId,
  }) async {
    if (_isShowing) return;
    _isShowing = true;
    try {
      await Navigator.of(context, rootNavigator: true).push(
        MaterialPageRoute(
          builder: (_) => SessionSummaryPage(sessionId: sessionId),
        ),
      );
    } finally {
      _isShowing = false;
      // Dismissed (or failed) — clear the pending id either way so the user
      // is never trapped in a summary loop. The cubit already cleared it on a
      // successful load; this covers the failure-then-close path.
      await AppStorage.clearActiveChargeSessionId();
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<SessionSummaryCubit>(param1: sessionId)..load(),
      child: const ResponsiveView(
        mobile: SessionSummaryMobileView(),
      ),
    );
  }
}

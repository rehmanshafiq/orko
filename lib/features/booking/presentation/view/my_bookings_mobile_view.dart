import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:orko_hubco/core/constants/app_colors.dart';
import 'package:orko_hubco/core/constants/app_sizes.dart';
import 'package:orko_hubco/core/utils/app_ui.dart';
import 'package:orko_hubco/core/utils/widgets/app_text.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_cubit.dart';
import 'package:orko_hubco/features/booking/presentation/cubit/my_bookings_state.dart';
import 'package:orko_hubco/features/booking/presentation/models/booking_session_model.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/active_session_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/booking_empty_state.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/bookings_tab_selector.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/history_booking_card.dart';
import 'package:orko_hubco/features/booking/presentation/widgets/upcoming_booking_card.dart';

class MyBookingsMobileView extends StatelessWidget {
  const MyBookingsMobileView({super.key});

  @override
  Widget build(BuildContext context) {
    final ui = AppUiColors.of(context);
    return Scaffold(
      backgroundColor: ui.scaffoldBackground,
      body: SafeArea(
        child: BlocBuilder<MyBookingsCubit, MyBookingsState>(
          builder: (context, state) {
            final cubit = context.read<MyBookingsCubit>();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: AppUtils.horizontal16Padding.add(
                    EdgeInsets.only(top: 12.h, bottom: 4.h),
                  ),
                  child: AppText(
                    'My Bookings',
                    color: ui.textPrimary,
                    fontSize: FontSizes.font22Sp,
                    fontWeight: FontWeights.weight700,
                  ),
                ),
                12.verticalSpace,
                Padding(
                  padding: AppUtils.horizontal16Padding,
                  child: BookingsTabSelector(
                    ui: ui,
                    selectedTab: state.selectedTab,
                    onTabSelected: cubit.selectTab,
                  ),
                ),
                16.verticalSpace,
                Expanded(
                  child: _TabContent(ui: ui, state: state, cubit: cubit),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _TabContent extends StatelessWidget {
  const _TabContent({
    required this.ui,
    required this.state,
    required this.cubit,
  });

  final AppUiColors ui;
  final MyBookingsState state;
  final MyBookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    switch (state.selectedTab) {
      case BookingTab.active:
        return _ActiveTab(ui: ui, sessions: state.activeSessions);
      case BookingTab.upcoming:
        return _UpcomingTab(
          ui: ui,
          bookings: state.upcomingBookings,
          cubit: cubit,
        );
      case BookingTab.history:
        return _HistoryTab(ui: ui, bookings: state.historyBookings);
    }
  }
}

class _ActiveTab extends StatelessWidget {
  const _ActiveTab({required this.ui, required this.sessions});

  final AppUiColors ui;
  final List<ActiveSession> sessions;

  @override
  Widget build(BuildContext context) {
    if (sessions.isEmpty) {
      return ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          BookingEmptyState(
            ui: ui,
            icon: Icons.bolt,
            title: 'No Active Sessions',
            subtitle: "You don't have any active charging sessions",
            accentColor: ui.brandPrimary,
            iconBackgroundColor: ui.brandPrimary.withValues(alpha: 0.12),
          ),
        ],
      );
    }
    return ListView.separated(
      padding: AppUtils.horizontal16Padding,
      itemCount: sessions.length,
      separatorBuilder: (_, __) => 14.verticalSpace,
      itemBuilder: (context, index) => ActiveSessionCard(
        ui: ui,
        session: sessions[index],
        onTap: () {},
      ),
    );
  }
}

class _UpcomingTab extends StatelessWidget {
  const _UpcomingTab({
    required this.ui,
    required this.bookings,
    required this.cubit,
  });

  final AppUiColors ui;
  final List<UpcomingBooking> bookings;
  final MyBookingsCubit cubit;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          BookingEmptyState(
            ui: ui,
            icon: Icons.calendar_today_outlined,
            title: 'No Upcoming Bookings',
            subtitle: "You don't have any upcoming reservations",
            accentColor: ui.brandPrimary,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: AppUtils.horizontal16Padding,
      itemCount: bookings.length,
      separatorBuilder: (_, __) => 14.verticalSpace,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return UpcomingBookingCard(
          ui: ui,
          booking: booking,
          onModify: () {},
          onCancel: () => cubit.cancelUpcoming(booking),
        );
      },
    );
  }
}

class _HistoryTab extends StatelessWidget {
  const _HistoryTab({required this.ui, required this.bookings});

  final AppUiColors ui;
  final List<HistoryBooking> bookings;

  @override
  Widget build(BuildContext context) {
    if (bookings.isEmpty) {
      return ListView(
        padding: AppUtils.horizontal16Padding,
        children: [
          BookingEmptyState(
            ui: ui,
            icon: Icons.history_rounded,
            title: 'No History',
            subtitle: "You haven't completed any charging sessions yet",
            accentColor: ui.brandPrimary,
          ),
        ],
      );
    }
    return ListView.separated(
      padding: AppUtils.horizontal16Padding,
      itemCount: bookings.length,
      separatorBuilder: (_, __) => 14.verticalSpace,
      itemBuilder: (context, index) => HistoryBookingCard(
        ui: ui,
        booking: bookings[index],
      ),
    );
  }
}

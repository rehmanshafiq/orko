import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/screens/login_screen.dart';
import 'package:orko_hubco/features/auth/presentation/screens/register_screen.dart';
import 'package:orko_hubco/features/auth/presentation/screens/verify_otp_screen.dart';
import 'package:orko_hubco/features/booking/presentation/pages/book_slot_page.dart';
import 'package:orko_hubco/features/booking/presentation/pages/booking_confirmation_page.dart';
import 'package:orko_hubco/features/booking/presentation/pages/booking_success_page.dart';
import 'package:orko_hubco/features/booking/presentation/pages/my_bookings_page.dart';
import 'package:orko_hubco/features/booking/presentation/screens/payment_method_screen.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/bottom_nav_shell.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/charging/presentation/page/charging_station_detail_page.dart';
import 'package:orko_hubco/features/map/presentation/home_screen.dart';
import 'package:orko_hubco/features/map/presentation/filter_screen.dart';
import 'package:orko_hubco/features/map/domain/entities/station_filters.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';
import 'package:orko_hubco/features/notifications/presentation/page/notifications_page.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:orko_hubco/features/onboarding/presentation/page/onboarding_page.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/charging_stats_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/charging/presentation/page/charging_status_page.dart';
import 'package:orko_hubco/features/profile/presentation/screens/profile_screen.dart';
import 'package:orko_hubco/features/vehicle/presentation/cubit/vehicle_cubit.dart';
import 'package:orko_hubco/features/search/presentation/page/search_page.dart';
import 'package:orko_hubco/features/splash/presentation/page/splash_page.dart';
import 'package:orko_hubco/features/trip/presentation/page/trip_planner_page.dart';

/// App-wide router configuration using go_router.
///
/// Route structure:
///   /login      → LoginScreen
///   /register   → RegisterScreen
///   /home       → BottomNavShell
///     ├── /home          → HomeScreen     (tab 0)
///     ├── /account       → ProfileScreen  (tab 1)
///     ├── /bookings      → MyBookingsPage (tab 2)
///     ├── /trip          → TripPlannerPage (tab 3)
///     └── /profile       → ChargingStatusPage (tab 4)
///   /search              → SearchPage (modal stack from map search bar)
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: false,
    routes: [
      // ── Splash Route ────────────────────────────────────────────────
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => BlocProvider(
          create: (_) => UserBloc(localDataSource: sl<AuthLocalDataSource>()),
          child: const SplashPage(),
        ),
      ),

      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<OnboardingCubit>()..loadSlides(),
          child: const OnboardingPage(),
        ),
      ),

      // ── Auth Routes ─────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: const LoginScreen(),
        ),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => BlocProvider(
          create: (_) => sl<AuthCubit>(),
          child: const RegisterScreen(),
        ),
      ),
      GoRoute(
        path: '/verify-otp',
        name: 'verify-otp',
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is Map ? extra : const {};
          return BlocProvider(
            create: (_) => sl<AuthCubit>(),
            child: VerifyOtpScreen(
              phoneNumber: args['phoneNumber']?.toString() ?? '',
              countryCode: args['countryCode']?.toString() ?? '+92',
              otpId: args['otpId']?.toString(),
            ),
          );
        },
      ),

      // Full-screen over shell (map marker → hub detail).
      GoRoute(
        path: '/station-detail',
        name: 'station-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final station = extra is HubcoLocationEntity ? extra : null;
          return ChargingStationDetailPage(station: station);
        },
      ),

      GoRoute(
        path: '/book-slot',
        name: 'book-slot',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          // Compatibility gate passes the station + resolved vehicle.
          if (extra is BookSlotArgs) {
            return BookSlotPage(
              locationId: extra.station.id,
              vehicleId: extra.vehicleId,
              stationName: extra.station.name,
              stationAddress: extra.station.address,
              fromTrip: extra.fromTrip,
            );
          }
          // Legacy callers pass only the station (no vehicle context).
          if (extra is HubcoLocationEntity) {
            return BookSlotPage(
              locationId: extra.id,
              stationName: extra.name,
              stationAddress: extra.address,
            );
          }
          return const BookSlotPage();
        },
      ),

      GoRoute(
        path: '/payment-method',
        name: 'payment-method',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PaymentMethodScreen(),
      ),

      GoRoute(
        path: '/booking-confirmation',
        name: 'booking-confirmation',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final paid = extra is int ? extra : 472;
          return BookingConfirmationPage(amountPaid: paid);
        },
      ),

      GoRoute(
        path: '/booking-success',
        name: 'booking-success',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is BookingSuccessArgs
              ? extra
              : const BookingSuccessArgs(
                  bookingRef: '—',
                  stationName: '—',
                  slotLabel: '—',
                  amountPaid: 0,
                );
          return BookingSuccessPage(args: args);
        },
      ),

      GoRoute(
        path: '/search',
        name: 'search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchPage(),
      ),

      GoRoute(
        path: '/notifications',
        name: 'notifications',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NotificationsPage(),
      ),

      // Filter results — its own MapCubit so filtering here never touches the
      // home map or its "Nearby Stations" row.
      GoRoute(
        path: '/filter-results',
        name: 'filter-results',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final filters =
              extra is StationFilters ? extra : const StationFilters();
          return BlocProvider(
            create: (_) => sl<MapCubit>()..applyFilters(filters),
            child: FilterScreen(filters: filters),
          );
        },
      ),

      // ── Main Shell (Bottom Nav) ─────────────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => sl<AuthCubit>()),
            ],
            child: BottomNavShell(navigationShell: navigationShell),
          );
        },
        branches: [
          // Tab 0: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                name: 'home',
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<MapCubit>()..loadHubcoLocations(),
                  child: const HomeScreen(),
                ),
              ),
            ],
          ),

          // Tab 1: Profile (account)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/account',
                name: 'account',
                // Rebuild on each Profile-tab tap so it always reopens on the
                // Profile sub-tab — see BottomNavShell.accountRefreshTick.
                builder: (context, state) => ValueListenableBuilder<int>(
                  valueListenable: BottomNavShell.accountRefreshTick,
                  builder: (context, tick, _) => MultiBlocProvider(
                    key: ValueKey<int>(tick),
                    providers: [
                      BlocProvider(
                        create: (_) => sl<ProfileCubit>()..loadProfile(),
                      ),
                      BlocProvider(create: (_) => sl<VehicleCubit>()),
                      BlocProvider(
                        create: (_) => sl<ChargingStatsCubit>()..load(),
                      ),
                    ],
                    child: const ProfileScreen(),
                  ),
                ),
              ),
            ],
          ),

          // Tab 2: Bookings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/bookings',
                name: 'bookings',
                // Rebuild on each Bookings-tab tap so it always reopens on the
                // Active tab — see BottomNavShell.bookingsRefreshTick.
                builder: (context, state) => ValueListenableBuilder<int>(
                  valueListenable: BottomNavShell.bookingsRefreshTick,
                  builder: (context, tick, _) => MyBookingsPage(
                    key: ValueKey<int>(tick),
                  ),
                ),
              ),
            ],
          ),
          // Tab 3: Trip
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trip',
                name: 'trip',
                // Kept alive by the indexed-stack shell so the planned trip and
                // form survive switching to another tab and back.
                builder: (context, state) => const TripPlannerPage(),
              ),
            ],
          ),
          // Tab 4: Profile (Charging Status)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ChargingStatusPage(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

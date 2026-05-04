import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/screens/login_screen.dart';
import 'package:orko_hubco/features/auth/presentation/screens/register_screen.dart';
import 'package:orko_hubco/features/booking/presentation/screens/book_a_slot_screen.dart';
import 'package:orko_hubco/features/booking/presentation/screens/booking_confirmation_screen.dart';
import 'package:orko_hubco/features/booking/presentation/screens/payment_method_screen.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/bottom_nav_shell.dart';
import 'package:orko_hubco/features/map/domain/entities/hubco_location_entity.dart';
import 'package:orko_hubco/features/map/presentation/charging_station_detail_screen.dart';
import 'package:orko_hubco/features/map/presentation/home_screen.dart';
import 'package:orko_hubco/features/map/presentation/cubit/map_cubit.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:orko_hubco/features/onboarding/presentation/page/onboarding_page.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/screens/charging_status_screen.dart';
import 'package:orko_hubco/features/profile/presentation/screens/profile_screen.dart';
import 'package:orko_hubco/features/search/presentation/screens/search_screen.dart';
import 'package:orko_hubco/features/splash/presentation/page/splash_page.dart';
import 'package:orko_hubco/features/trip/presentation/screens/trip_planner_screen.dart';

/// App-wide router configuration using go_router.
///
/// Route structure:
///   /login      → LoginScreen
///   /register   → RegisterScreen
///   /home       → BottomNavShell
///     ├── /home          → HomeScreen     (tab 0)
///     ├── /account       → ProfileScreen  (tab 1)
///     ├── /bookings      → BookASlotScreen (tab 2)
///     ├── /trip          → TripPlannerScreen (tab 3)
///     └── /profile       → ChargingStatusScreen (tab 4)
///   /search              → SearchScreen (modal stack from map search bar)
class AppRouter {
  AppRouter._();

  static final _rootNavigatorKey = GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    debugLogDiagnostics: true,
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

      // Full-screen over shell (map marker → hub detail).
      GoRoute(
        path: '/station-detail',
        name: 'station-detail',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          final extra = state.extra;
          final station = extra is HubcoLocationEntity ? extra : null;
          return ChargingStationDetailScreen(station: station);
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
          return BookingConfirmationScreen(amountPaid: paid);
        },
      ),

      GoRoute(
        path: '/search',
        name: 'search',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const SearchScreen(),
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
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<ProfileCubit>()..loadProfile(),
                  child: const ProfileScreen(),
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
                builder: (context, state) => const BookASlotScreen(),
              ),
            ],
          ),
          // Tab 3: Trip
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/trip',
                name: 'trip',
                builder: (context, state) => const TripPlannerScreen(),
              ),
            ],
          ),
          // Tab 4: Profile (Charging Status)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ChargingStatusScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

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
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/bottom_nav_shell.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/home_screen.dart';
import 'package:orko_hubco/features/onboarding/presentation/bloc/onboarding_cubit.dart';
import 'package:orko_hubco/features/onboarding/presentation/page/onboarding_page.dart';
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
///     ├── /search        → SearchScreen   (tab 1)
///     ├── /bookings      → BookASlotScreen (tab 2)
///     └── /trip          → TripPlannerScreen (tab 3)
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
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),

          // Tab 1: Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                name: 'search',
                builder: (context, state) => const SearchScreen(),
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
        ],
      ),
    ],
  );
}

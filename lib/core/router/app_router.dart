import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/global_bloc/bloc/user_bloc.dart';
import 'package:orko_hubco/features/auth/data/datasources/local/auth_local_datasource.dart';
import 'package:orko_hubco/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:orko_hubco/features/auth/presentation/screens/login_screen.dart';
import 'package:orko_hubco/features/auth/presentation/screens/register_screen.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/bottom_nav_shell.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/home_screen.dart';
import 'package:orko_hubco/features/bottom_navigation/presentation/screens/settings_screen.dart';
import 'package:orko_hubco/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:orko_hubco/features/profile/presentation/screens/profile_screen.dart';
import 'package:orko_hubco/features/splash/page/splash_page.dart';

/// App-wide router configuration using go_router.
///
/// Route structure:
///   /login      → LoginScreen
///   /register   → RegisterScreen
///   /home       → BottomNavShell
///     ├── /home          → HomeScreen     (tab 0)
///     ├── /home/profile  → ProfileScreen  (tab 1)
///     └── /home/settings → SettingsScreen (tab 2)
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

          // Tab 1: Profile
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => BlocProvider(
                  create: (_) => sl<ProfileCubit>(),
                  child: const ProfileScreen(),
                ),
              ),
            ],
          ),

          // Tab 2: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],

    // ── Redirect Logic ──────────────────────────────────────────────
    // redirect: (context, state) {
    //   final isLoggedIn = sl<LocalStorageService>().isLoggedIn;
    //   final isAuthRoute = state.matchedLocation == '/login' ||
    //       state.matchedLocation == '/register';
    //
    //   if (!isLoggedIn && !isAuthRoute) return '/login';
    //   if (isLoggedIn && isAuthRoute) return '/home';
    //   return null;
    // },
  );
}

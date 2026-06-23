import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_storage/get_storage.dart';
import 'package:orko_hubco/core/di/injection_container.dart';
import 'package:orko_hubco/core/router/app_router.dart';
import 'package:orko_hubco/core/services/push_notification_service.dart';
import 'package:orko_hubco/core/theme/app_material_theme.dart';
import 'package:orko_hubco/core/theme/theme_cubit.dart';
import 'package:orko_hubco/features/remote_config/data/services/remote_config_service.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize local storage
  await GetStorage.init();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the FCM background/terminated handler before runApp.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Warm the remote config (Firebase → GetStorage → asset fallback).
  // Never throws for individual layer failures; safe to await at startup.
  await RemoteConfigService.instance.initialize();

  // Initialize all dependencies
  await initDependencies();

  // Wire up push notifications (permission, token, listeners). Best-effort and
  // non-blocking so it never delays first paint.
  unawaited(sl<PushNotificationService>().initialize());

  // Lock orientation to portrait
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  runApp(const OrkoHubCoApp());
}

class OrkoHubCoApp extends StatelessWidget {
  const OrkoHubCoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (_, __) => BlocProvider<ThemeCubit>.value(
        value: sl<ThemeCubit>(),
        child: BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return MaterialApp.router(
              title: 'Orko HubCo',
              debugShowCheckedModeBanner: false,
              theme: AppMaterialTheme.light,
              darkTheme: AppMaterialTheme.dark,
              themeMode: themeMode,
              routerConfig: AppRouter.router,
            );
          },
        ),
      ),
    );
  }
}

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/constants/app_constants.dart';
import 'core/di/injection.dart';
import 'core/router/app_router.dart';
import 'core/services/sync_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  // Keep native splash visible while async initialization runs.
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ── Firebase ──────────────────────────────────────────────────────────────
  await Firebase.initializeApp();

  // Route Flutter errors to Crashlytics in release mode
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // ── Hive local storage ────────────────────────────────────────────────────
  await Hive.initFlutter();
  await Hive.openBox<Map>(AppConstants.expenseBox);
  await Hive.openBox<Map>(AppConstants.pendingSyncBox);
  await Hive.openBox(AppConstants.settingsBox);

  // ── Dependency injection ──────────────────────────────────────────────────
  configureDependencies();

  // ── Background sync ──────────────────────────────────────────────────────
  getIt<SyncService>().start();

  // ── Remove native splash ──────────────────────────────────────────────────
  FlutterNativeSplash.remove();

  runApp(const TrackrApp());
}

class TrackrApp extends StatelessWidget {
  const TrackrApp({super.key});

  @override
  Widget build(BuildContext context) {
    // AuthBloc is a singleton — provided at the root so every widget can access it.
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
      child: Builder(
        builder: (context) {
          final authBloc = context.read<AuthBloc>();
          final router = AppRouter.build(authBloc);

          return ScreenUtilInit(
            designSize: const Size(390, 844), // iPhone 14 base design
            minTextAdapt: true,
            splitScreenMode: true,
            builder: (_, __) => MaterialApp.router(
              title: AppConstants.appName,
              debugShowCheckedModeBanner: false,
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: ThemeMode.dark,
              routerConfig: router,
            ),
          );
        },
      ),
    );
  }
}

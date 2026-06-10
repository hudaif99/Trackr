import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../bloc/auth_bloc.dart';

/// Invisible bridge screen shown only while [AuthBloc] resolves the initial
/// auth state. The native splash (flutter_native_splash) is visible on top of
/// this until [FlutterNativeSplash.remove()] is called in main.dart, so the
/// user never sees a blank frame.
///
/// Once auth resolves, GoRouter's redirect logic takes over and navigates to
/// either the dashboard or the login/onboarding flow.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // Kick off the auth check so GoRouter can redirect once resolved.
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppConstants.routeDashboard);
        } else if (state is AuthUnauthenticated) {
          context.go(AppConstants.routeLogin);
        }
      },
      // Solid background that matches the native splash so there's no flash.
      child: const Scaffold(backgroundColor: AppColors.background),
    );
  }
}

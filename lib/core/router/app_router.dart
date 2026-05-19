import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../di/injection.dart';

import '../../../features/ai/presentation/bloc/ai_categorization_cubit.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/register_page.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../../features/analytics/presentation/pages/analytics_page.dart';
import '../../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';

/// Application router using go_router with a shell for bottom navigation.
class AppRouter {
  static final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');
  static final _shellNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'shell');

  static GoRouter build(AuthBloc authBloc) {
    return GoRouter(
      navigatorKey: _rootNavigatorKey,
      initialLocation: AppConstants.routeSplash,
      refreshListenable: _BlocListenable(authBloc),
      redirect: (context, state) async {
        final authState = authBloc.state;
        final location = state.matchedLocation;

        // ── Auth redirect ──────────────────────────────────────────────────
        final isAuthenticated = authState is AuthAuthenticated;
        final isAuthRoute = location.startsWith('/auth');
        final isSplash = location == '/';
        final isOnboarding = location == '/onboarding';

        if (!isAuthenticated && !isAuthRoute && !isSplash && !isOnboarding) {
          // Check onboarding
          final prefs = await SharedPreferences.getInstance();
          final onboardingDone =
              prefs.getBool(AppConstants.onboardingCompleteKey) ?? false;
          return onboardingDone
              ? AppConstants.routeLogin
              : AppConstants.routeOnboarding;
        }

        if (isAuthenticated && (isAuthRoute || isOnboarding)) {
          return AppConstants.routeDashboard;
        }

        return null;
      },
      routes: [
        // ── Splash ────────────────────────────────────────────────────────
        GoRoute(
          path: AppConstants.routeSplash,
          builder: (_, __) => const SplashPage(),
        ),

        // ── Onboarding ────────────────────────────────────────────────────
        GoRoute(
          path: AppConstants.routeOnboarding,
          builder: (_, __) => const OnboardingPage(),
        ),

        // ── Auth ──────────────────────────────────────────────────────────
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (_, __) => const LoginPage(),
        ),
        GoRoute(
          path: AppConstants.routeRegister,
          builder: (_, __) => const RegisterPage(),
        ),

        // ── Shell (bottom nav) ────────────────────────────────────────────
        ShellRoute(
          navigatorKey: _shellNavigatorKey,
          builder: (context, state, child) => _ShellScaffold(child: child),
          routes: [
            GoRoute(
              path: AppConstants.routeDashboard,
              pageBuilder: (_, __) => const NoTransitionPage(
                child: DashboardPage(),
              ),
            ),
            GoRoute(
              path: AppConstants.routeExpenses,
              pageBuilder: (_, __) => const NoTransitionPage(
                child: ExpenseListPage(),
              ),
            ),
            GoRoute(
              path: AppConstants.routeAnalytics,
              pageBuilder: (_, __) => const NoTransitionPage(
                child: AnalyticsPage(),
              ),
            ),
          ],
        ),

        // ── Expenses (full-screen routes) ─────────────────────────────────
        GoRoute(
          path: AppConstants.routeAddExpense,
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, __) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<ExpenseFormBloc>()),
              BlocProvider(create: (_) => getIt<AiCategorizationCubit>()),
            ],
            child: const AddExpensePage(),
          ),
        ),
      ],
    );
  }
}

/// Shell scaffold with bottom navigation bar.
class _ShellScaffold extends StatelessWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => getIt<DashboardBloc>()),
        BlocProvider(create: (_) => getIt<ExpenseListBloc>()),
        BlocProvider(create: (_) => getIt<AnalyticsBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final location = GoRouterState.of(context).matchedLocation;
          final index = _indexFromLocation(location);

          return Scaffold(
            body: child,
            bottomNavigationBar: NavigationBar(
              selectedIndex: index,
              onDestinationSelected: (i) {
                switch (i) {
                  case 0:
                    context.go(AppConstants.routeDashboard);
                  case 1:
                    context.go(AppConstants.routeExpenses);
                  case 2:
                    context.go(AppConstants.routeAnalytics);
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.receipt_long_outlined),
                  selectedIcon: Icon(Icons.receipt_long_rounded),
                  label: 'Expenses',
                ),
                NavigationDestination(
                  icon: Icon(Icons.bar_chart_outlined),
                  selectedIcon: Icon(Icons.bar_chart_rounded),
                  label: 'Analytics',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _indexFromLocation(String location) {
    if (location.startsWith('/home/expenses')) return 1;
    if (location.startsWith('/home/analytics')) return 2;
    return 0;
  }
}

/// Makes GoRouter react to auth state changes.
class _BlocListenable extends ChangeNotifier {
  final AuthBloc _bloc;

  _BlocListenable(this._bloc) {
    _bloc.stream.listen((_) => notifyListeners());
  }
}

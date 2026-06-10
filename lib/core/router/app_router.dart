import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fluxo/core/theme/app_colors.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';
import '../di/injection.dart';

import '../../../features/ai/presentation/bloc/ai_categorization_cubit.dart';
import '../../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../../features/auth/presentation/pages/login_page.dart';
import '../../../features/auth/presentation/pages/register_page.dart';
import '../../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../../features/auth/presentation/pages/splash_page.dart';
import '../../../features/analytics/presentation/bloc/analytics_bloc.dart';
import '../../../features/analytics/presentation/pages/analytics_page.dart';
import '../../../features/dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../../features/expenses/presentation/bloc/expense_bloc.dart';
import '../../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../../features/expenses/presentation/pages/expense_detail_page.dart';
import '../../../features/expenses/presentation/pages/expense_list_page.dart';
import '../../../features/expenses/domain/entities/expense_entity.dart';
import '../../../features/onboarding/presentation/pages/onboarding_page.dart';

/// Application router using go_router with a shell for bottom navigation.
class AppRouter {
  static final _rootNavigatorKey =
      GlobalKey<NavigatorState>(debugLabel: 'root');
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
        final isAuthRoute = location == AppConstants.routeLogin ||
            location == AppConstants.routeRegister ||
            location == '/forgot-password';
        final isSplash = location == AppConstants.routeSplash;
        final isOnboarding = location == AppConstants.routeOnboarding;

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
        GoRoute(
          path: '/forgot-password',
          builder: (_, __) => const ForgotPasswordPage(),
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
          builder: (_, state) => MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => getIt<ExpenseFormBloc>()),
              BlocProvider(create: (_) => getIt<AiCategorizationCubit>()),
            ],
            child: const AddExpensePage(),
          ),
        ),

        // ── Expense detail ────────────────────────────────────────────────
        GoRoute(
          path: '/expenses/:id',
          parentNavigatorKey: _rootNavigatorKey,
          builder: (_, state) {
            final expense = state.extra as ExpenseEntity;
            return ExpenseDetailPage(expense: expense);
          },
        ),
      ],
    );
  }
}

/// Shell scaffold with bottom navigation bar and double-tap to exit.
class _ShellScaffold extends StatefulWidget {
  final Widget child;

  const _ShellScaffold({required this.child});

  @override
  State<_ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends State<_ShellScaffold> {
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: getIt<DashboardBloc>()),
        BlocProvider.value(value: getIt<ExpenseListBloc>()),
        BlocProvider.value(value: getIt<AnalyticsBloc>()),
      ],
      child: Builder(
        builder: (context) {
          final location = GoRouterState.of(context).matchedLocation;
          final index = _indexFromLocation(location);

          return PopScope(
            canPop: false,
            onPopInvokedWithResult: (didPop, result) {
              if (didPop) return;

              if (index != 0) {
                // If not on the Home tab, pressing back goes to Home
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    context.go(AppConstants.routeDashboard);
                  }
                });
                return;
              }

              // Double-tap to exit from Home tab
              final now = DateTime.now();
              if (_lastBackPressTime == null ||
                  now.difference(_lastBackPressTime!) >
                      const Duration(seconds: 2)) {
                _lastBackPressTime = now;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Press back again to exit'),
                    duration: Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  SystemNavigator.pop();
                });
              }
            },
            child: Scaffold(
              body: widget.child,
              floatingActionButton: index == 2
                  ? BlocBuilder<AnalyticsBloc, AnalyticsState>(
                      builder: (context, state) {
                        if (state is AnalyticsLoaded) return const SizedBox.shrink();
                        return _buildFab(context);
                      },
                    )
                  : _buildFab(context),
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
                    icon: FaIcon(FontAwesomeIcons.house, size: 18),
                    selectedIcon: FaIcon(FontAwesomeIcons.house, size: 18),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    icon: FaIcon(FontAwesomeIcons.receipt, size: 18),
                    selectedIcon: FaIcon(FontAwesomeIcons.receipt, size: 18),
                    label: 'Expenses',
                  ),
                  NavigationDestination(
                    icon: FaIcon(FontAwesomeIcons.chartLine, size: 18),
                    selectedIcon: FaIcon(FontAwesomeIcons.chartLine, size: 18),
                    label: 'Analytics',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFab(BuildContext context) {
    return FloatingActionButton(
      heroTag: 'shell_fab',
      backgroundColor: AppColors.primary,
      onPressed: () => context.push(AppConstants.routeAddExpense),
      child: const FaIcon(FontAwesomeIcons.plus, color: Colors.white, size: 20),
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

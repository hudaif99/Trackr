import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_error_states.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../expenses/presentation/widgets/expense_tile.dart';
import '../../../expenses/presentation/utils/expense_delete_helper.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../bloc/dashboard_bloc.dart';
import "../widgets/category_pie_chart.dart";
import "../widgets/empty_recent_transactions.dart";
import "../widgets/monthly_line_chart.dart";
import "../widgets/quick_stats_row.dart";
import "../widgets/section_header.dart";
import "../widgets/spending_hero_card.dart";

/// Main dashboard screen — the heart of Trackr.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) return const SizedBox.shrink();

        final user = authState.user;

        // Only load once — skip if data is already loaded or being loaded.
        // Dispatching on every build() caused a flash each time the user
        // switched back to this tab.
        final dashboardState = context.read<DashboardBloc>().state;
        if (dashboardState is DashboardInitial) {
          context.read<DashboardBloc>().add(DashboardLoadRequested(user.uid));
        }

        return Scaffold(
          backgroundColor: AppColors.background,
          body: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) => switch (state) {
              DashboardInitial() ||
              DashboardLoading() =>
                _buildSkeleton(context),
              DashboardLoaded(:final summary) =>
                _buildContent(context, summary, user.name),
              DashboardError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => context
                      .read<DashboardBloc>()
                      .add(DashboardRefreshRequested(user.uid)),
                ),
            },
          ),
        );
      },
    );
  }

  Widget _buildSkeleton(BuildContext context) {
    return const SingleChildScrollView(
      physics: NeverScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          SizedBox(height: 60),
          SpendingCardSkeleton(),
          SizedBox(height: 16),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: SkeletonLoader(width: double.infinity, height: 200),
          ),
          SizedBox(height: 16),
          ExpenseTileSkeleton(),
          ExpenseTileSkeleton(),
          ExpenseTileSkeleton(),
        ],
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    DashboardSummaryEntity summary,
    String userName,
  ) {
    return RefreshIndicator(
      color: AppColors.primary,
      backgroundColor: AppColors.surface,
      onRefresh: () async {
        final authState = context.read<AuthBloc>().state;
        if (authState is AuthAuthenticated) {
          context
              .read<DashboardBloc>()
              .add(DashboardRefreshRequested(authState.user.uid));
        }
      },
      child: CustomScrollView(
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────
          SliverAppBar(
            backgroundColor: AppColors.background,
            floating: true,
            snap: true,
            expandedHeight: 0,
            toolbarHeight: 72,
            title: Row(
              children: [
                // Avatar
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Good ${_greeting()}',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    Text(
                      userName,
                      style: AppTextStyles.titleMedium,
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: IconButton(
                  icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket,
                      size: 16),
                  color: AppColors.expense,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Log Out'),
                        content:
                            const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel',
                                style:
                                    TextStyle(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context
                                  .read<AuthBloc>()
                                  .add(const AuthLogoutRequested());
                            },
                            child: const Text('Logout',
                                style: TextStyle(color: AppColors.expense)),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // ── Spending hero card ─────────────────────────────────
                SpendingHeroCard(summary: summary),
                const SizedBox(height: 28),

                // ── Quick stats row ────────────────────────────────────
                QuickStatsRow(summary: summary),
                const SizedBox(height: 28),

                // ── Category pie chart ─────────────────────────────────
                const SectionHeader(
                  title: 'Spending by Category',
                  subtitle: 'This month',
                ),
                const SizedBox(height: 12),
                CategoryPieChart(breakdown: summary.categoryBreakdown),
                const SizedBox(height: 28),

                // ── Monthly trend ──────────────────────────────────────
                const SectionHeader(
                  title: 'Monthly Trend',
                  subtitle: 'Last 6 months',
                ),
                const SizedBox(height: 12),
                MonthlyLineChart(trend: summary.monthlyTrend),
                const SizedBox(height: 28),

                // ── Recent transactions ────────────────────────────────
                SectionHeader(
                  title: 'Recent',
                  actionLabel: 'See all',
                  onAction: () => context.go(AppConstants.routeExpenses),
                ),
                const SizedBox(height: 12),
                if (summary.recentExpenses.isEmpty)
                  EmptyRecentTransactions(
                    onAdd: () => context.go(AppConstants.routeAddExpense),
                  )
                else
                  ...summary.recentExpenses.map(
                    (e) => ExpenseTile(
                      expense: e,
                      onTap: () => context.push('/expenses/${e.id}', extra: e),
                      onDelete: () => ExpenseDeleteHelper.confirmAndDelete(context, e),
                    ),
                  ),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}

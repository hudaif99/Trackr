import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/double_x.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../core/widgets/empty_error_states.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/presentation/widgets/expense_tile.dart';
import '../bloc/dashboard_bloc.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Main dashboard screen — the heart of Fluxo.
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) return const SizedBox.shrink();

        final user = authState.user;
        context
            .read<DashboardBloc>()
            .add(DashboardLoadRequested(user.uid));

        return Scaffold(
          backgroundColor: AppColors.background,
          body: BlocBuilder<DashboardBloc, DashboardState>(
            builder: (context, state) => switch (state) {
              DashboardInitial() || DashboardLoading() =>
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
          floatingActionButton: FloatingActionButton(
            heroTag: 'dash_fab',
            onPressed: () => context.go(AppConstants.routeAddExpense),
            child: const Icon(Icons.add_rounded),
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
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Good ${_greeting()}, $userName 👋',
                  style: AppTextStyles.titleMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text('Dashboard', style: AppTextStyles.headlineSmall),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                color: AppColors.textSecondary,
                onPressed: () {},
              ),
            ],
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Spending hero card ─────────────────────────────────
                _SpendingHeroCard(summary: summary),
                const SizedBox(height: 24),

                // ── Category pie chart ─────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Spending by Category',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                _CategoryPieChart(breakdown: summary.categoryBreakdown),
                const SizedBox(height: 24),

                // ── Monthly trend ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Monthly Trend',
                    style: AppTextStyles.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                _MonthlyLineChart(trend: summary.monthlyTrend),
                const SizedBox(height: 24),

                // ── Recent transactions ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent', style: AppTextStyles.titleLarge),
                      TextButton(
                        onPressed: () =>
                            context.go(AppConstants.routeExpenses),
                        child: Text(
                          'See all',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary.recentExpenses.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text('No expenses yet — add your first one!'),
                    ),
                  )
                else
                  ...summary.recentExpenses.map(
                    (e) => ExpenseTile(
                      expense: e,
                      onTap: () =>
                          context.go('/expenses/${e.id}'),
                    ),
                  ),
                const SizedBox(height: 80),
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

// ── Spending Hero Card ────────────────────────────────────────────────────────

class _SpendingHeroCard extends StatelessWidget {
  final DashboardSummaryEntity summary;

  const _SpendingHeroCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final isUp = summary.isIncreased;
    final changePct = summary.monthOverMonthChange.abs().toStringAsFixed(1);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'This Month',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            summary.totalThisMonth.inr,
            style: AppTextStyles.amountHero,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                isUp
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: isUp ? AppColors.expense : AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '$changePct% vs last month',
                style: AppTextStyles.bodySmall.copyWith(
                  color: isUp ? AppColors.expense : AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Category Pie Chart ────────────────────────────────────────────────────────

class _CategoryPieChart extends StatefulWidget {
  final Map<ExpenseCategory, double> breakdown;

  const _CategoryPieChart({required this.breakdown});

  @override
  State<_CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<_CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    if (widget.breakdown.isEmpty) {
      return const SizedBox(height: 200);
    }

    final total = widget.breakdown.values.fold(0.0, (s, v) => s + v);
    final entries = widget.breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final sections = entries.asMap().entries.map((e) {
      final index = e.key;
      final entry = e.value;
      final isTouched = index == _touchedIndex;
      final pct = total > 0 ? (entry.value / total) * 100 : 0;

      return PieChartSectionData(
        value: entry.value,
        color: _categoryColor(entry.key),
        radius: isTouched ? 60 : 52,
        title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      );
    }).toList();

    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sections: sections,
                centerSpaceRadius: 40,
                sectionsSpace: 2,
                pieTouchData: PieTouchData(
                  touchCallback: (event, response) {
                    setState(() {
                      _touchedIndex = response?.touchedSection
                              ?.touchedSectionIndex ??
                          -1;
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.take(5).map((e) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _categoryColor(e.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      e.key.displayName,
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Color _categoryColor(ExpenseCategory cat) => switch (cat) {
        ExpenseCategory.food => AppColors.catFood,
        ExpenseCategory.travel => AppColors.catTravel,
        ExpenseCategory.shopping => AppColors.catShopping,
        ExpenseCategory.bills => AppColors.catBills,
        ExpenseCategory.entertainment => AppColors.catEntertainment,
        ExpenseCategory.health => AppColors.catHealth,
        ExpenseCategory.fuel => AppColors.catFuel,
        ExpenseCategory.education => AppColors.catEducation,
        ExpenseCategory.other => AppColors.catOther,
      };
}

// ── Monthly Line Chart ────────────────────────────────────────────────────────

class _MonthlyLineChart extends StatelessWidget {
  final List<MonthlyTrendPoint> trend;

  const _MonthlyLineChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox(height: 160);

    final spots = trend.asMap().entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.total))
        .toList();

    final maxY = trend.map((t) => t.total).reduce((a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      height: 180,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox();
                  return Text(
                    trend[i].month.shortMonth,
                    style: AppTextStyles.labelSmall,
                  );
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0,
          maxX: (trend.length - 1).toDouble(),
          minY: 0,
          maxY: maxY * 1.2,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.35,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.08),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

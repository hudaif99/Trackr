import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
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
                  decoration: BoxDecoration(
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
                  icon: const FaIcon(FontAwesomeIcons.arrowRightFromBracket, size: 16),
                  color: AppColors.expense,
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Log Out'),
                        content: const Text('Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel', style: TextStyle(color: AppColors.textSecondary)),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              context.read<AuthBloc>().add(const AuthLogoutRequested());
                            },
                            child: const Text('Logout', style: TextStyle(color: AppColors.expense)),
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
                _SpendingHeroCard(summary: summary),
                const SizedBox(height: 28),

                // ── Quick stats row ────────────────────────────────────
                _QuickStatsRow(summary: summary),
                const SizedBox(height: 28),

                // ── Category pie chart ─────────────────────────────────
                _SectionHeader(
                  title: 'Spending by Category',
                  subtitle: 'This month',
                ),
                const SizedBox(height: 12),
                _CategoryPieChart(breakdown: summary.categoryBreakdown),
                const SizedBox(height: 28),

                // ── Monthly trend ──────────────────────────────────────
                _SectionHeader(
                  title: 'Monthly Trend',
                  subtitle: 'Last 6 months',
                ),
                const SizedBox(height: 12),
                _MonthlyLineChart(trend: summary.monthlyTrend),
                const SizedBox(height: 28),

                // ── Recent transactions ────────────────────────────────
                _SectionHeader(
                  title: 'Recent',
                  actionLabel: 'See all',
                  onAction: () => context.go(AppConstants.routeExpenses),
                ),
                const SizedBox(height: 12),
                if (summary.recentExpenses.isEmpty)
                  _EmptyRecentTransactions(
                    onAdd: () => context.go(AppConstants.routeAddExpense),
                  )
                else
                  ...summary.recentExpenses.map(
                    (e) => ExpenseTile(
                      expense: e,
                      onTap: () => context.push('/expenses/${e.id}', extra: e),
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

// ── Section Header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.titleLarge),
              if (subtitle != null)
                Text(
                  subtitle!,
                  style: AppTextStyles.labelSmall,
                ),
            ],
          ),
          if (actionLabel != null && onAction != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  actionLabel!,
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
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
    final hasLastMonth = summary.totalLastMonth > 0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0D9E6E), Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -10,
            top: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -10,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'This Month',
                      style: AppTextStyles.labelMedium.copyWith(
                        color: Colors.white.withValues(alpha: 0.75),
                        letterSpacing: 0.8,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentMonth(),
                        style: AppTextStyles.labelSmall.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  summary.totalThisMonth.inr,
                  style: AppTextStyles.amountHero.copyWith(
                    color: Colors.white,
                    fontSize: 38,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          FaIcon(
                            isUp
                                ? FontAwesomeIcons.arrowUp
                                : FontAwesomeIcons.arrowDown,
                            color:
                                isUp ? const Color(0xFFFCA5A5) : Colors.white,
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            hasLastMonth
                                ? '$changePct% vs last month'
                                : 'First month tracked',
                            style: AppTextStyles.labelSmall.copyWith(
                              color:
                                  isUp ? const Color(0xFFFCA5A5) : Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Last month',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.55),
                          ),
                        ),
                        Text(
                          summary.totalLastMonth.inr,
                          style: AppTextStyles.amountSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _currentMonth() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[now.month - 1]} ${now.year}';
  }
}

// ── Quick Stats Row ───────────────────────────────────────────────────────────

class _QuickStatsRow extends StatelessWidget {
  final DashboardSummaryEntity summary;

  const _QuickStatsRow({required this.summary});

  @override
  Widget build(BuildContext context) {
    final txCount = summary.recentExpenses.length;
    final topCategory = summary.categoryBreakdown.isNotEmpty
        ? (summary.categoryBreakdown.entries.toList()
              ..sort((a, b) => b.value.compareTo(a.value)))
            .first
            .key
            .displayName
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: _StatCard(
              icon: FontAwesomeIcons.receipt,
              iconColor: AppColors.accent,
              label: 'Transactions',
              value: txCount.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _StatCard(
              icon: FontAwesomeIcons.tag,
              iconColor: AppColors.warning,
              label: 'Top Category',
              value: topCategory,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTextStyles.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty State Widget ────────────────────────────────────────────────────────

class _ChartEmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String hint;

  const _ChartEmptyState({
    required this.icon,
    required this.message,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: FaIcon(icon, color: AppColors.textDisabled, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _EmptyRecentTransactions extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyRecentTransactions({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              shape: BoxShape.circle,
            ),
            child: const FaIcon(FontAwesomeIcons.receipt,
                color: Colors.white, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            'No expenses yet',
            style: AppTextStyles.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Start tracking by adding your first expense',
            style: AppTextStyles.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onAdd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                'Add Expense',
                style: AppTextStyles.labelMedium.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
      return const _ChartEmptyState(
        icon: Icons.pie_chart_outline_rounded,
        message: 'No spending data yet',
        hint: 'Add expenses to see your category breakdown',
      );
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
        radius: isTouched ? 65 : 54,
        title: isTouched ? '${pct.toStringAsFixed(0)}%' : '',
        titleStyle: AppTextStyles.labelSmall.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );
    }).toList();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: SizedBox(
        height: 200,
        child: Row(
          children: [
            Expanded(
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 36,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        _touchedIndex =
                            response?.touchedSection?.touchedSectionIndex ?? -1;
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.take(6).map((e) {
                final pct = total > 0
                    ? (e.value / total * 100).toStringAsFixed(0)
                    : '0';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
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
                      const SizedBox(width: 8),
                      Text(
                        e.key.displayName,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$pct%',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
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
    if (trend.isEmpty) {
      return const _ChartEmptyState(
        icon: Icons.show_chart_rounded,
        message: 'No trend data yet',
        hint: 'Your spending trend will appear here after a few months',
      );
    }

    final spots = trend
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.total))
        .toList();

    final maxY = trend.map((t) => t.total).reduce(math.max);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
            getDrawingHorizontalLine: (val) => FlLine(
              color: AppColors.cardBorder,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  // Only draw at exact integer positions to avoid duplicate
                  // labels caused by fl_chart generating fractional ticks.
                  if (val != i.toDouble()) return const SizedBox();
                  if (i < 0 || i >= trend.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      trend[i].month.shortMonth,
                      style: AppTextStyles.labelSmall,
                    ),
                  );
                },
                interval: 1,
                reservedSize: 28,
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
          maxY: maxY * 1.25,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              curveSmoothness: 0.4,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                  radius: 3.5,
                  color: AppColors.primary,
                  strokeColor: AppColors.surface,
                  strokeWidth: 2,
                ),
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.18),
                    AppColors.primary.withValues(alpha: 0.0),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

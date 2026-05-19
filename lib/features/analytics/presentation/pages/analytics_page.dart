import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/extensions/double_x.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_error_states.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../dashboard/domain/entities/dashboard_entities.dart';
import '../bloc/analytics_bloc.dart';

class AnalyticsPage extends StatelessWidget {
  const AnalyticsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) return const SizedBox.shrink();
        final userId = authState.user.uid;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(title: const Text('Analytics')),
          body: BlocBuilder<AnalyticsBloc, AnalyticsState>(
            builder: (context, state) => switch (state) {
              AnalyticsInitial() => _initLoad(context, userId),
              AnalyticsLoading() => _skeleton(),
              AnalyticsLoaded(:final summary) =>
                _content(context, summary),
              AnalyticsError(:final message) => ErrorState(
                  message: message,
                  onRetry: () => context
                      .read<AnalyticsBloc>()
                      .add(AnalyticsLoadRequested(userId)),
                ),
            },
          ),
        );
      },
    );
  }

  Widget _initLoad(BuildContext context, String userId) {
    context.read<AnalyticsBloc>().add(AnalyticsLoadRequested(userId));
    return _skeleton();
  }

  Widget _skeleton() => ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          SkeletonLoader(width: double.infinity, height: 120),
          SizedBox(height: 16),
          SkeletonLoader(width: double.infinity, height: 200),
          SizedBox(height: 16),
          SkeletonLoader(width: double.infinity, height: 160),
        ],
      );

  Widget _content(BuildContext context, AnalyticsSummary summary) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Stat cards ────────────────────────────────────────────────────
        _StatCards(summary: summary),
        const SizedBox(height: 24),

        // ── Category breakdown ────────────────────────────────────────────
        Text('Category Breakdown', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        _CategoryBreakdown(breakdown: summary.breakdown),
        const SizedBox(height: 24),

        // ── Monthly bar chart ─────────────────────────────────────────────
        Text('Monthly Spending', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        _MonthlyBarChart(trend: summary.monthlyTrend),
        const SizedBox(height: 24),

        // ── Weekly trend ──────────────────────────────────────────────────
        Text('This Month — Weekly', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        _WeeklyChart(weekly: summary.weeklyTrend),
        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Stat Cards ────────────────────────────────────────────────────────────────

class _StatCards extends StatelessWidget {
  final AnalyticsSummary summary;

  const _StatCards({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'This Month',
            value: summary.totalThisMonth.inrCompact,
            icon: Icons.calendar_month_rounded,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(
            label: 'Monthly Avg',
            value: summary.averageMonthly.inrCompact,
            icon: Icons.show_chart_rounded,
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(value, style: AppTextStyles.amountLarge),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}

// ── Category Breakdown ────────────────────────────────────────────────────────

class _CategoryBreakdown extends StatelessWidget {
  final List<CategoryBreakdownEntity> breakdown;

  const _CategoryBreakdown({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: breakdown.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(item.category.emoji,
                    style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(item.category.displayName,
                              style: AppTextStyles.titleSmall),
                          Text(item.total.inr,
                              style: AppTextStyles.amountSmall),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: item.percentage / 100,
                          backgroundColor: AppColors.surfaceVariant,
                          valueColor: AlwaysStoppedAnimation(
                              _catColor(item.category)),
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _catColor(ExpenseCategory c) => switch (c) {
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

// ── Monthly Bar Chart ─────────────────────────────────────────────────────────

class _MonthlyBarChart extends StatelessWidget {
  final List<MonthlyTrendPoint> trend;

  const _MonthlyBarChart({required this.trend});

  @override
  Widget build(BuildContext context) {
    if (trend.isEmpty) return const SizedBox.shrink();

    final maxY = trend.map((t) => t.total).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= trend.length) return const SizedBox();
                  return Text(trend[i].month.shortMonth,
                      style: AppTextStyles.labelSmall);
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: trend.asMap().entries.map((e) {
            final isCurrent = e.key == trend.length - 1;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.total,
                  color: isCurrent ? AppColors.primary : AppColors.surfaceVariant,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ── Weekly Trend Chart ────────────────────────────────────────────────────────

class _WeeklyChart extends StatelessWidget {
  final List<WeeklyPoint> weekly;

  const _WeeklyChart({required this.weekly});

  @override
  Widget build(BuildContext context) {
    if (weekly.isEmpty) return const SizedBox.shrink();

    final maxY = weekly.map((w) => w.total).reduce((a, b) => a > b ? a : b);

    return Container(
      height: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: BarChart(
        BarChartData(
          maxY: maxY > 0 ? maxY * 1.3 : 100,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (val, _) {
                  final i = val.toInt();
                  if (i < 0 || i >= weekly.length) return const SizedBox();
                  return Text(weekly[i].label, style: AppTextStyles.labelSmall);
                },
                reservedSize: 24,
              ),
            ),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          barGroups: weekly.asMap().entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: e.value.total,
                  color: AppColors.accent,
                  width: 20,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}

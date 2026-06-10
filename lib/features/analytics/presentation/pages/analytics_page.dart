import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/empty_error_states.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../bloc/analytics_bloc.dart';
import "../widgets/category_breakdown.dart";
import "../widgets/monthly_bar_chart.dart";
import "../widgets/stat_cards.dart";
import "../widgets/weekly_chart.dart";

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
              AnalyticsLoaded(:final summary) => _content(context, summary),
              AnalyticsEmpty() => const EmptyState(
                  icon: FontAwesomeIcons.chartPie,
                  title: 'No analytics yet',
                  subtitle: 'Start tracking expenses to see your insights',
                ),
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
        StatCards(summary: summary),
        const SizedBox(height: 24),

        // ── Category breakdown ────────────────────────────────────────────
        Text('Category Breakdown', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        CategoryBreakdown(breakdown: summary.breakdown),
        const SizedBox(height: 24),

        // ── Monthly bar chart ─────────────────────────────────────────────
        Text('Monthly Spending', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        MonthlyBarChart(trend: summary.monthlyTrend),
        const SizedBox(height: 24),

        // ── Weekly trend ──────────────────────────────────────────────────
        Text('This Month — Weekly', style: AppTextStyles.titleLarge),
        const SizedBox(height: 12),
        WeeklyChart(weekly: summary.weeklyTrend),
        const SizedBox(height: 32),
      ],
    );
  }
}

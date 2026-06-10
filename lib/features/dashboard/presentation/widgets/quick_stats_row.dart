import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/dashboard_entities.dart';

class QuickStatsRow extends StatelessWidget {
  final DashboardSummaryEntity summary;

  const QuickStatsRow({super.key, required this.summary});

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
            child: StatCard(
              icon: FontAwesomeIcons.receipt,
              iconColor: AppColors.accent,
              label: 'Transactions',
              value: txCount.toString(),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StatCard(
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

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const StatCard({
    super.key,
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

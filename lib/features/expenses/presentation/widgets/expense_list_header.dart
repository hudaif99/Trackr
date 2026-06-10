import 'package:flutter/material.dart';
import '../../../../core/extensions/double_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExpenseListHeader extends StatelessWidget {
  final double total;
  final int count;

  const ExpenseListHeader({
    super.key,
    required this.total,
    required this.count,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This Month',
                style: AppTextStyles.labelSmall,
              ),
              const SizedBox(height: 4),
              Text(
                total.inr,
                style: AppTextStyles.amountLarge.copyWith(
                  color: AppColors.expense,
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Transactions', style: AppTextStyles.labelSmall),
              const SizedBox(height: 4),
              Text(
                '$count',
                style: AppTextStyles.amountLarge,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../../core/extensions/double_x.dart';
import '../../../../core/extensions/date_time_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/expense_entity.dart';

/// Reusable expense list tile with category icon, amount, and date.
class ExpenseTile extends StatelessWidget {
  final ExpenseEntity expense;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const ExpenseTile({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ── Category icon ─────────────────────────────────────────────
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _categoryColor(expense.category).withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(
                  expense.category.emoji,
                  style: const TextStyle(fontSize: 22),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Title + date ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.title,
                    style: AppTextStyles.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${expense.date.relativeLabel} · ${expense.category.displayName}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),

            // ── Amount ────────────────────────────────────────────────────
            Text(
              expense.amount.inr,
              style: AppTextStyles.amountSmall.copyWith(
                color: AppColors.expense,
              ),
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

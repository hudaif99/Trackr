import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expense_entity.dart';
import 'expense_detail_divider.dart';
import 'expense_detail_row.dart';

class ExpenseMetaCard extends StatelessWidget {
  final ExpenseEntity expense;

  const ExpenseMetaCard({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          ExpenseDetailRow(
            icon: FontAwesomeIcons.hashtag,
            label: 'Expense ID',
            value: expense.id.substring(0, 8).toUpperCase(),
            onTap: () {
              Clipboard.setData(ClipboardData(text: expense.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          const ExpenseDetailDivider(),
          ExpenseDetailRow(
            icon: FontAwesomeIcons.rotateRight,
            label: 'Sync status',
            value: expense.isSynced ? 'Synced ✓' : 'Pending sync',
            valueColor:
                expense.isSynced ? AppColors.primary : AppColors.warning,
          ),
        ],
      ),
    );
  }
}

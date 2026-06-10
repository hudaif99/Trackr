import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expense_entity.dart';
import 'expense_detail_divider.dart';
import 'expense_detail_row.dart';

class ExpenseDetailCard extends StatelessWidget {
  final ExpenseEntity expense;

  const ExpenseDetailCard({super.key, required this.expense});

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
            icon: FontAwesomeIcons.tag,
            label: 'Category',
            value: '${expense.category.emoji}  ${expense.category.displayName}',
          ),
          const ExpenseDetailDivider(),
          ExpenseDetailRow(
            icon: FontAwesomeIcons.calendarDays,
            label: 'Date',
            value: _fullDate(expense.date),
          ),
          const ExpenseDetailDivider(),
          ExpenseDetailRow(
            icon: FontAwesomeIcons.creditCard,
            label: 'Payment',
            value: expense.paymentMethod.displayName,
          ),
        ],
      ),
    );
  }

  String _fullDate(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

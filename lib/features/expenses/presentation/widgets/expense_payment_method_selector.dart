import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/expense_entity.dart';

class ExpensePaymentMethodSelector extends StatelessWidget {
  final PaymentMethod selectedMethod;
  final ValueChanged<PaymentMethod> onChanged;

  const ExpensePaymentMethodSelector({
    super.key,
    required this.selectedMethod,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Payment Method',
            style: AppTextStyles.labelMedium.copyWith(
              color: AppColors.textSecondary,
            )),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: PaymentMethod.values.map((m) {
            final selected = selectedMethod == m;
            return ChoiceChip(
              label: Text(m.displayName),
              selected: selected,
              onSelected: (_) => onChanged(m),
              selectedColor: AppColors.accent.withOpacity(0.15),
              side: BorderSide(
                color: selected ? AppColors.accent : AppColors.border,
              ),
              labelStyle: AppTextStyles.labelMedium.copyWith(
                color: selected ? AppColors.accent : AppColors.textPrimary,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

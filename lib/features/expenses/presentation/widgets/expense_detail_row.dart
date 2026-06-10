import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExpenseDetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const ExpenseDetailRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(icon, size: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodySmall),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const FaIcon(FontAwesomeIcons.copy,
                  size: 12, color: AppColors.textDisabled),
            ],
          ],
        ),
      ),
    );
  }
}

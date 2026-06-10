import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class ExpenseDetailDivider extends StatelessWidget {
  const ExpenseDetailDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 60,
      color: AppColors.divider,
    );
  }
}

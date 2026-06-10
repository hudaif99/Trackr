import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';

class ExpenseNoteCard extends StatelessWidget {
  final String note;

  const ExpenseNoteCard({super.key, required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.noteSticky,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Note',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(note, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

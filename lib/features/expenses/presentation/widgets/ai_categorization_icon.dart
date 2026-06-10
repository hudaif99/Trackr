import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../ai/presentation/bloc/ai_categorization_cubit.dart';

class AiCategorizationIcon extends StatelessWidget {
  final AiCategorizationState state;

  const AiCategorizationIcon({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      AiCategorizationLoading() => const Padding(
          padding: EdgeInsets.all(12),
          child: SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      AiCategorizationSuccess(:final usedFallback) => Tooltip(
          message: usedFallback ? 'Categorized locally' : 'AI categorized',
          child: FaIcon(
            FontAwesomeIcons.wandMagicSparkles,
            color: usedFallback ? AppColors.textSecondary : AppColors.primary,
            size: 18,
          ),
        ),
      _ => const SizedBox.shrink(), // Ensure we return a widget instead of null when not explicitly handled
    };
  }
}

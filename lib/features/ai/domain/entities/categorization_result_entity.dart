import 'package:equatable/equatable.dart';
import '../../../expenses/domain/entities/expense_entity.dart';

/// Result of AI expense categorization.
class CategorizationResultEntity extends Equatable {
  final ExpenseCategory category;
  final double confidence;
  final bool usedFallback;

  const CategorizationResultEntity({
    required this.category,
    required this.confidence,
    this.usedFallback = false,
  });

  @override
  List<Object?> get props => [category, confidence, usedFallback];
}

import '../../../../core/errors/failures.dart';
import '../entities/categorization_result_entity.dart';
import '../repositories/ai_repository.dart';

/// Categorizes an expense description using AI with keyword fallback.
class CategorizeExpenseUseCase {
  final AiRepository _repository;

  const CategorizeExpenseUseCase(this._repository);

  Future<(CategorizationResultEntity?, Failure?)> call(String description) =>
      _repository.categorize(description);
}

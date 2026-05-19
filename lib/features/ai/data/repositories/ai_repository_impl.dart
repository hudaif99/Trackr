import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/categorization_result_entity.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../domain/repositories/ai_repository.dart';
import '../datasources/gemini_datasource.dart';
import '../datasources/local_keyword_datasource.dart';

class AiRepositoryImpl implements AiRepository {
  final GeminiDataSource _gemini;
  final LocalKeywordDataSource _keyword;

  const AiRepositoryImpl(this._gemini, this._keyword);

  @override
  Future<(CategorizationResultEntity?, Failure?)> categorize(
    String description,
  ) async {
    if (description.trim().isEmpty) {
      return (
        const CategorizationResultEntity(
          category: ExpenseCategory.other,
          confidence: 0,
          usedFallback: true,
        ),
        null
      );
    }

    // 1. Try Gemini first
    try {
      final category = await _gemini.categorize(description);
      return (
        CategorizationResultEntity(
          category: category,
          confidence: 0.92,
        ),
        null,
      );
    } on AiException {
      // Fall through to keyword fallback
    } catch (_) {
      // Fall through to keyword fallback
    }

    // 2. Keyword fallback
    final category = _keyword.categorize(description);
    return (
      CategorizationResultEntity(
        category: category,
        confidence: 0.6,
        usedFallback: true,
      ),
      null,
    );
  }
}

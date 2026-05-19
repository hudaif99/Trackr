import '../../../../core/errors/failures.dart';
import '../entities/categorization_result_entity.dart';

abstract class AiRepository {
  /// Categorizes an expense description using AI (Gemini) with keyword fallback.
  Future<(CategorizationResultEntity?, Failure?)> categorize(String description);
}

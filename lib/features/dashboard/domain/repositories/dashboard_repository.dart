import '../../../../core/errors/failures.dart';
import '../entities/dashboard_entities.dart';

abstract class DashboardRepository {
  Future<(DashboardSummaryEntity?, Failure?)> getDashboardSummary(
    String userId,
  );
}

import '../../../../core/errors/failures.dart';
import '../entities/dashboard_entities.dart';
import '../repositories/dashboard_repository.dart';

class GetDashboardSummaryUseCase {
  final DashboardRepository _repository;

  const GetDashboardSummaryUseCase(this._repository);

  Future<(DashboardSummaryEntity?, Failure?)> call(String userId) =>
      _repository.getDashboardSummary(userId);
}

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/dashboard_entities.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DashboardRemoteDataSource _dataSource;

  const DashboardRepositoryImpl(this._dataSource);

  @override
  Future<(DashboardSummaryEntity?, Failure?)> getDashboardSummary(
    String userId,
  ) async {
    try {
      final summary = await _dataSource.getDashboardSummary(userId);
      return (summary, null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message));
    } catch (e) {
      return (null, UnknownFailure(message: e.toString()));
    }
  }
}

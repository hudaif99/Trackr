import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../datasources/expense_local_datasource.dart';
import '../datasources/expense_remote_datasource.dart';
import '../models/expense_model.dart';

/// Offline-first implementation of [ExpenseRepository].
///
/// Strategy:
/// - Reads return local data immediately, then refresh from Firestore.
/// - Writes go to Hive first (marked isSynced=false), then to Firestore.
/// - If offline, the write is stored locally only and will be synced on next
///   successful connection.
class ExpenseRepositoryImpl implements ExpenseRepository {
  final ExpenseRemoteDataSource _remote;
  final ExpenseLocalDataSource _local;
  final NetworkInfo _networkInfo;

  const ExpenseRepositoryImpl({
    required ExpenseRemoteDataSource remote,
    required ExpenseLocalDataSource local,
    required NetworkInfo networkInfo,
  })  : _remote = remote,
        _local = local,
        _networkInfo = networkInfo;

  @override
  Future<(List<ExpenseEntity>, Failure?)> getExpenses({
    required String userId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    // Return cached data immediately for instant UI
    final cached = _local.getExpenses(
      userId: userId,
      category: category?.name,
      from: from,
      to: to,
    );

    // Attempt background refresh if online
    if (await _networkInfo.isConnected) {
      try {
        final remote = await _remote.getExpenses(
          userId: userId,
          category: category?.name,
          from: from,
          to: to,
          limit: limit,
        );
        await _local.saveAll(remote);
        return (remote as List<ExpenseEntity>, null);
      } on ServerException catch (e) {
        // Return cached data on remote error
        return (cached as List<ExpenseEntity>, ServerFailure(e.message));
      }
    }

    return (cached as List<ExpenseEntity>, null);
  }

  @override
  Future<(ExpenseEntity?, Failure?)> getExpenseById(String id) async {
    try {
      final local = _local.getExpenseById(id);
      if (local != null) return (local, null);

      if (await _networkInfo.isConnected) {
        final remote = await _remote.getExpenseById(id);
        return (remote, null);
      }
      return (null, const CacheFailure(message: 'Expense not found offline.'));
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message));
    } on CacheException catch (e) {
      return (null, CacheFailure(message: e.message));
    }
  }

  @override
  Future<(ExpenseEntity?, Failure?)> createExpense(ExpenseEntity expense) async {
    try {
      // Always write locally first
      final local = ExpenseModel.fromEntity(
        expense.copyWith(isSynced: false),
      );
      await _local.saveExpense(local);

      if (await _networkInfo.isConnected) {
        final synced = await _remote.createExpense(expense);
        final syncedModel =
            ExpenseModel.fromEntity(synced.copyWith(isSynced: true));
        await _local.saveExpense(syncedModel);
        return (syncedModel, null);
      }
      return (local, null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message));
    } on CacheException catch (e) {
      return (null, CacheFailure(message: e.message));
    }
  }

  @override
  Future<(ExpenseEntity?, Failure?)> updateExpense(ExpenseEntity expense) async {
    try {
      await _local.saveExpense(expense.copyWith(isSynced: false));

      if (await _networkInfo.isConnected) {
        final updated = await _remote.updateExpense(expense);
        final syncedModel =
            ExpenseModel.fromEntity(updated.copyWith(isSynced: true));
        await _local.saveExpense(syncedModel);
        return (syncedModel, null);
      }
      return (expense, null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message));
    }
  }

  @override
  Future<Failure?> deleteExpense(String id) async {
    try {
      await _local.deleteExpense(id);
      if (await _networkInfo.isConnected) {
        await _remote.deleteExpense(id);
      }
      return null;
    } on ServerException catch (e) {
      return ServerFailure(e.message);
    }
  }

  @override
  Stream<List<ExpenseEntity>> watchExpenses(String userId) =>
      _remote.watchExpenses(userId);
}

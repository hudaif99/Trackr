import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
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
/// - Reads return local data immediately. If online, refreshes from Firestore
///   and merges, preserving any pending (unsynced) local items.
/// - Writes go to Hive first (marked isSynced=false), then to Firestore.
/// - If offline, the write is also added to the pending_sync queue so
///   [SyncService] can push it to Firestore when connectivity is restored.
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

  Box<Map> get _pendingBox => Hive.box<Map>(AppConstants.pendingSyncBox);

  @override
  Future<(List<ExpenseEntity>, Failure?)> getExpenses({
    required String userId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    if (await _networkInfo.isConnected) {
      try {
        final remote = await _remote.getExpenses(
          userId: userId,
          category: category?.name,
          from: from,
          to: to,
          limit: limit,
        );

        // Collect any pending (unsynced) local items BEFORE overwriting cache,
        // so they are never lost when remote data replaces local storage.
        final pending = _local
            .getExpenses(userId: userId)
            .where((e) => !e.isSynced)
            .toList();

        await _local.saveAll(remote);

        // Re-save unsynced items so they survive the saveAll above.
        for (final p in pending) {
          await _local.saveExpense(p);
        }

        // Merge: remote list + any pending items not yet on the server.
        final remoteIds = remote.map((e) => e.id).toSet();
        final merged = <ExpenseEntity>[
          ...remote,
          ...pending.where((e) => !remoteIds.contains(e.id)),
        ]..sort((a, b) => b.date.compareTo(a.date));

        return (merged, null);
      } on ServerException catch (e) {
        // Remote failed — fall through to local cache below.
        final cached = _local.getExpenses(
          userId: userId,
          category: category?.name,
          from: from,
          to: to,
        );
        return (cached as List<ExpenseEntity>, ServerFailure(e.message));
      }
    }

    // Offline — return local cache (includes pending unsynced items).
    final cached = _local.getExpenses(
      userId: userId,
      category: category?.name,
      from: from,
      to: to,
    );
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
  Future<(ExpenseEntity?, Failure?)> createExpense(
      ExpenseEntity expense) async {
    try {
      // Always write locally first, marked as unsynced.
      final local = ExpenseModel.fromEntity(expense.copyWith(isSynced: false));
      await _local.saveExpense(local);

      if (await _networkInfo.isConnected) {
        final synced = await _remote.createExpense(expense);
        final syncedModel =
            ExpenseModel.fromEntity(synced.copyWith(isSynced: true));
        await _local.saveExpense(syncedModel);
        return (syncedModel, null);
      }

      // Offline — add to the pending queue for SyncService.
      await _pendingBox.put(expense.id, {
        'id': expense.id,
        'operation': 'create',
      });
      return (local, null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message));
    } on CacheException catch (e) {
      return (null, CacheFailure(message: e.message));
    }
  }

  @override
  Future<(ExpenseEntity?, Failure?)> updateExpense(
      ExpenseEntity expense) async {
    try {
      await _local.saveExpense(expense.copyWith(isSynced: false));

      if (await _networkInfo.isConnected) {
        final updated = await _remote.updateExpense(expense);
        final syncedModel =
            ExpenseModel.fromEntity(updated.copyWith(isSynced: true));
        await _local.saveExpense(syncedModel);
        return (syncedModel, null);
      }

      await _pendingBox.put(expense.id, {
        'id': expense.id,
        'operation': 'update',
      });
      return (expense, null);
    } on ServerException catch (e) {
      return (null, ServerFailure(e.message));
    }
  }

  @override
  Future<Failure?> deleteExpense(String id) async {
    try {
      await _local.deleteExpense(id);
      // Remove from pending queue if it was queued offline.
      await _pendingBox.delete(id);

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

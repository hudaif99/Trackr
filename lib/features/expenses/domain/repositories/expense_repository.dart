import '../../../../core/errors/failures.dart';
import '../entities/expense_entity.dart';

/// Contract for expense data operations.
///
/// All methods return Dart record tuples — no external Either dependency needed.
abstract class ExpenseRepository {
  /// Fetches all expenses for [userId], most recent first.
  /// Reads from local cache immediately, then syncs from remote.
  Future<(List<ExpenseEntity>, Failure?)> getExpenses({
    required String userId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    int limit,
  });

  /// Fetches a single expense by [id].
  Future<(ExpenseEntity?, Failure?)> getExpenseById(String id);

  /// Creates a new expense locally and queues a remote sync.
  Future<(ExpenseEntity?, Failure?)> createExpense(ExpenseEntity expense);

  /// Updates an existing expense.
  Future<(ExpenseEntity?, Failure?)> updateExpense(ExpenseEntity expense);

  /// Deletes an expense by [id].
  Future<Failure?> deleteExpense(String id);


  /// Returns a stream of expenses for realtime updates (Firestore listener).
  Stream<List<ExpenseEntity>> watchExpenses(String userId);
}

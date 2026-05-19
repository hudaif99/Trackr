import '../../../../core/errors/failures.dart';
import '../entities/expense_entity.dart';
import '../repositories/expense_repository.dart';

/// Fetch all expenses, with optional filters.
class GetExpensesUseCase {
  final ExpenseRepository _repository;

  const GetExpensesUseCase(this._repository);

  Future<(List<ExpenseEntity>, Failure?)> call({
    required String userId,
    ExpenseCategory? category,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) =>
      _repository.getExpenses(
        userId: userId,
        category: category,
        from: from,
        to: to,
        limit: limit,
      );

  Stream<List<ExpenseEntity>> watch(String userId) =>
      _repository.watchExpenses(userId);
}

/// Fetch a single expense by ID.
class GetExpenseByIdUseCase {
  final ExpenseRepository _repository;

  const GetExpenseByIdUseCase(this._repository);

  Future<(ExpenseEntity?, Failure?)> call(String id) =>
      _repository.getExpenseById(id);
}

/// Create a new expense.
class CreateExpenseUseCase {
  final ExpenseRepository _repository;

  const CreateExpenseUseCase(this._repository);

  Future<(ExpenseEntity?, Failure?)> call(ExpenseEntity expense) =>
      _repository.createExpense(expense);
}

/// Update an existing expense.
class UpdateExpenseUseCase {
  final ExpenseRepository _repository;

  const UpdateExpenseUseCase(this._repository);

  Future<(ExpenseEntity?, Failure?)> call(ExpenseEntity expense) =>
      _repository.updateExpense(expense);
}

/// Delete an expense by ID.
class DeleteExpenseUseCase {
  final ExpenseRepository _repository;

  const DeleteExpenseUseCase(this._repository);

  Future<Failure?> call(String id) => _repository.deleteExpense(id);
}


import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/expense_usecases.dart';
import 'expense_event_state.dart';

export 'expense_event_state.dart';
import '../../domain/entities/expense_entity.dart';

/// Manages the expense list — loads, filters, and deletes.
class ExpenseListBloc extends Bloc<ExpenseListEvent, ExpenseListState> {
  final GetExpensesUseCase _getExpenses;
  final DeleteExpenseUseCase _deleteExpense;

  String? _currentUserId;
  ExpenseCategory? _activeFilter;

  ExpenseListBloc({
    required GetExpensesUseCase getExpenses,
    required DeleteExpenseUseCase deleteExpense,
  })  : _getExpenses = getExpenses,
        _deleteExpense = deleteExpense,
        super(const ExpenseListInitial()) {
    on<ExpensesLoadRequested>(_onLoad);
    on<ExpensesRefreshRequested>(_onRefresh);
    on<ExpenseDeleteRequested>(_onDelete);
    on<ExpenseFilterChanged>(_onFilterChanged);
  }

  Future<void> _onLoad(
    ExpensesLoadRequested event,
    Emitter<ExpenseListState> emit,
  ) async {
    _currentUserId = event.userId;
    _activeFilter = event.category;
    emit(const ExpenseListLoading());

    final (expenses, failure) = await _getExpenses(
      userId: event.userId,
      category: event.category,
      from: event.from,
      to: event.to,
    );

    if (failure != null) {
      emit(ExpenseListError(failure.message));
      return;
    }

    if (expenses.isEmpty) {
      emit(ExpenseListEmpty(activeFilter: _activeFilter));
      return;
    }

    final total = _calcMonthTotal(expenses);
    emit(ExpenseListLoaded(
      expenses: expenses,
      activeFilter: _activeFilter,
      totalThisMonth: total,
    ));
  }

  Future<void> _onRefresh(
    ExpensesRefreshRequested event,
    Emitter<ExpenseListState> emit,
  ) async {
    add(ExpensesLoadRequested(
      userId: event.userId,
      category: _activeFilter,
    ));
  }

  Future<void> _onDelete(
    ExpenseDeleteRequested event,
    Emitter<ExpenseListState> emit,
  ) async {
    final failure = await _deleteExpense(event.expenseId);
    if (failure != null) {
      emit(ExpenseListError(failure.message));
      return;
    }
    // Reload the list
    if (_currentUserId != null) {
      add(ExpensesLoadRequested(
        userId: _currentUserId!,
        category: _activeFilter,
      ));
    }
  }

  Future<void> _onFilterChanged(
    ExpenseFilterChanged event,
    Emitter<ExpenseListState> emit,
  ) async {
    _activeFilter = event.category;
    if (_currentUserId != null) {
      add(ExpensesLoadRequested(
        userId: _currentUserId!,
        category: event.category,
      ));
    }
  }

  double _calcMonthTotal(List expenses) {
    final now = DateTime.now();
    return expenses
        .where((e) => e.date.year == now.year && e.date.month == now.month)
        .fold(0.0, (sum, e) => sum + e.amount);
  }
}

/// Manages creating and updating an expense.
class ExpenseFormBloc extends Bloc<ExpenseFormEvent, ExpenseFormState> {
  final CreateExpenseUseCase _create;
  final UpdateExpenseUseCase _update;

  ExpenseFormBloc({
    required CreateExpenseUseCase create,
    required UpdateExpenseUseCase update,
  })  : _create = create,
        _update = update,
        super(const ExpenseFormInitial()) {
    on<ExpenseFormSubmitted>(_onSubmit);
    on<ExpenseFormUpdated>(_onUpdate);
  }

  Future<void> _onSubmit(
    ExpenseFormSubmitted event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(const ExpenseFormSubmitting());
    final (expense, failure) = await _create(event.expense);
    if (failure != null) {
      emit(ExpenseFormFailure(failure.message));
      return;
    }
    emit(ExpenseFormSuccess(expense!));
  }

  Future<void> _onUpdate(
    ExpenseFormUpdated event,
    Emitter<ExpenseFormState> emit,
  ) async {
    emit(const ExpenseFormSubmitting());
    final (expense, failure) = await _update(event.expense);
    if (failure != null) {
      emit(ExpenseFormFailure(failure.message));
      return;
    }
    emit(ExpenseFormSuccess(expense!));
  }
}

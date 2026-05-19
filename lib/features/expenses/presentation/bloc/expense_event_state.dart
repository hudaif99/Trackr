import 'package:equatable/equatable.dart';
import '../../domain/entities/expense_entity.dart';

// ── Expense List Events ───────────────────────────────────────────────────────

sealed class ExpenseListEvent extends Equatable {
  const ExpenseListEvent();
  @override
  List<Object?> get props => [];
}

final class ExpensesLoadRequested extends ExpenseListEvent {
  final String userId;
  final ExpenseCategory? category;
  final DateTime? from;
  final DateTime? to;

  const ExpensesLoadRequested({
    required this.userId,
    this.category,
    this.from,
    this.to,
  });

  @override
  List<Object?> get props => [userId, category, from, to];
}

final class ExpenseDeleteRequested extends ExpenseListEvent {
  final String expenseId;
  const ExpenseDeleteRequested(this.expenseId);
  @override
  List<Object?> get props => [expenseId];
}

final class ExpenseFilterChanged extends ExpenseListEvent {
  final ExpenseCategory? category;
  const ExpenseFilterChanged(this.category);
  @override
  List<Object?> get props => [category];
}

final class ExpensesRefreshRequested extends ExpenseListEvent {
  final String userId;
  const ExpensesRefreshRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── Expense List States ───────────────────────────────────────────────────────

sealed class ExpenseListState extends Equatable {
  const ExpenseListState();
  @override
  List<Object?> get props => [];
}

final class ExpenseListInitial extends ExpenseListState {
  const ExpenseListInitial();
}

final class ExpenseListLoading extends ExpenseListState {
  const ExpenseListLoading();
}

final class ExpenseListLoaded extends ExpenseListState {
  final List<ExpenseEntity> expenses;
  final ExpenseCategory? activeFilter;
  final double totalThisMonth;

  const ExpenseListLoaded({
    required this.expenses,
    this.activeFilter,
    this.totalThisMonth = 0,
  });

  @override
  List<Object?> get props => [expenses, activeFilter, totalThisMonth];
}

final class ExpenseListEmpty extends ExpenseListState {
  final ExpenseCategory? activeFilter;
  const ExpenseListEmpty({this.activeFilter});
  @override
  List<Object?> get props => [activeFilter];
}

final class ExpenseListError extends ExpenseListState {
  final String message;
  const ExpenseListError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Expense Form Events ───────────────────────────────────────────────────────

sealed class ExpenseFormEvent extends Equatable {
  const ExpenseFormEvent();
  @override
  List<Object?> get props => [];
}

final class ExpenseFormSubmitted extends ExpenseFormEvent {
  final ExpenseEntity expense;
  const ExpenseFormSubmitted(this.expense);
  @override
  List<Object?> get props => [expense];
}

final class ExpenseFormUpdated extends ExpenseFormEvent {
  final ExpenseEntity expense;
  const ExpenseFormUpdated(this.expense);
  @override
  List<Object?> get props => [expense];
}

// ── Expense Form States ───────────────────────────────────────────────────────

sealed class ExpenseFormState extends Equatable {
  const ExpenseFormState();
  @override
  List<Object?> get props => [];
}

final class ExpenseFormInitial extends ExpenseFormState {
  const ExpenseFormInitial();
}

final class ExpenseFormSubmitting extends ExpenseFormState {
  const ExpenseFormSubmitting();
}

final class ExpenseFormSuccess extends ExpenseFormState {
  final ExpenseEntity expense;
  const ExpenseFormSuccess(this.expense);
  @override
  List<Object?> get props => [expense];
}

final class ExpenseFormFailure extends ExpenseFormState {
  final String message;
  const ExpenseFormFailure(this.message);
  @override
  List<Object?> get props => [message];
}

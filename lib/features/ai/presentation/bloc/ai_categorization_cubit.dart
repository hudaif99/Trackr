import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../domain/usecases/categorize_expense_usecase.dart';

// ── State ──────────────────────────────────────────────────────────────────

sealed class AiCategorizationState extends Equatable {
  const AiCategorizationState();
  @override
  List<Object?> get props => [];
}

final class AiCategorizationIdle extends AiCategorizationState {
  const AiCategorizationIdle();
}

final class AiCategorizationLoading extends AiCategorizationState {
  const AiCategorizationLoading();
}

final class AiCategorizationSuccess extends AiCategorizationState {
  final ExpenseCategory category;
  final bool usedFallback;

  const AiCategorizationSuccess({
    required this.category,
    this.usedFallback = false,
  });

  @override
  List<Object?> get props => [category, usedFallback];
}

final class AiCategorizationFailure extends AiCategorizationState {
  final String message;
  const AiCategorizationFailure(this.message);
  @override
  List<Object?> get props => [message];
}

// ── Cubit ──────────────────────────────────────────────────────────────────

/// A Cubit (simpler than BLoC) that triggers AI categorization.
///
/// Called from [AddExpensePage] after 800ms debounce when the user
/// types in the expense title field.
class AiCategorizationCubit extends Cubit<AiCategorizationState> {
  final CategorizeExpenseUseCase _categorize;

  AiCategorizationCubit(this._categorize) : super(const AiCategorizationIdle());

  Future<void> categorize(String description) async {
    if (description.trim().length < 3) {
      emit(const AiCategorizationIdle());
      return;
    }

    emit(const AiCategorizationLoading());

    final (result, failure) = await _categorize(description);

    if (failure != null) {
      emit(AiCategorizationFailure(failure.message));
      return;
    }

    emit(AiCategorizationSuccess(
      category: result!.category,
      usedFallback: result.usedFallback,
    ));
  }

  void reset() => emit(const AiCategorizationIdle());
}

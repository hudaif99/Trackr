import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/widgets/confirm_dialog.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../analytics/presentation/bloc/analytics_bloc.dart';
import '../../../dashboard/presentation/bloc/dashboard_bloc.dart';
import '../../domain/entities/expense_entity.dart';
import '../../domain/repositories/expense_repository.dart';
import '../bloc/expense_bloc.dart';

/// Helper to delete an expense and synchronize state across all tabs.
abstract final class ExpenseDeleteHelper {
  /// Shows a confirmation dialog and deletes the expense if confirmed.
  /// Returns true if the expense was deleted.
  static Future<bool> confirmAndDelete(
    BuildContext context,
    ExpenseEntity expense,
  ) async {
    final confirm = await showConfirmDialog(
      context,
      title: 'Delete Expense',
      message: 'Are you sure you want to delete "${expense.title}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      isDestructive: true,
    );

    if (confirm != true) return false;

    // Use root context or ensure mounted before reading bloc
    if (!context.mounted) return false;

    final userId = context.read<AuthBloc>().state is AuthAuthenticated
        ? (context.read<AuthBloc>().state as AuthAuthenticated).user.uid
        : null;

    if (userId == null) return false;

    // Delete directly via repository to await completion
    final failure = await getIt<ExpenseRepository>().deleteExpense(expense.id);

    if (failure != null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete expense: ${failure.message}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }

    // Dispatch refresh events to all tabs
    getIt<ExpenseListBloc>().add(ExpensesRefreshRequested(userId));
    getIt<DashboardBloc>().add(DashboardRefreshRequested(userId));
    getIt<AnalyticsBloc>().add(AnalyticsLoadRequested(userId));

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Expense deleted')),
      );
    }

    return true;
  }
}

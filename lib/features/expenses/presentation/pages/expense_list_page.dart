import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_error_states.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';
import '../utils/expense_delete_helper.dart';
import '../widgets/expense_list_header.dart';
import '../widgets/expense_tile.dart';

/// Full expense list with category filter tabs and pull-to-refresh.
class ExpenseListPage extends StatelessWidget {
  const ExpenseListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) return const SizedBox.shrink();
        final userId = authState.user.uid;

        return DefaultTabController(
          length: ExpenseCategory.values.length + 1, // +1 for "All"
          child: Scaffold(
            backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Expenses'),
              bottom: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicatorColor: AppColors.primary,
                dividerColor: AppColors.divider,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                tabs: [
                  const Tab(text: 'All'),
                  ...ExpenseCategory.values.map(
                    (c) => Tab(text: c.displayName),
                  ),
                ],
                onTap: (index) {
                  final category =
                      index == 0 ? null : ExpenseCategory.values[index - 1];
                  context
                      .read<ExpenseListBloc>()
                      .add(ExpenseFilterChanged(category));
                },
              ),
            ),
            body: BlocBuilder<ExpenseListBloc, ExpenseListState>(
              builder: (context, state) => switch (state) {
                ExpenseListInitial() => _initLoad(context, userId),
                ExpenseListLoading() => _skeleton(),
                ExpenseListLoaded(:final expenses, :final totalThisMonth) =>
                  _list(context, expenses, userId, totalThisMonth),
                ExpenseListEmpty() => const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No expenses yet',
                    subtitle: 'Tap + to add your first expense.',
                  ),
                ExpenseListError(:final message) => ErrorState(
                    message: message,
                    onRetry: () => context
                        .read<ExpenseListBloc>()
                        .add(ExpensesRefreshRequested(userId)),
                  ),
              },
            ),
            floatingActionButton: FloatingActionButton(
              heroTag: 'expense_fab',
              onPressed: () => context.push(AppConstants.routeAddExpense),
              child: const FaIcon(FontAwesomeIcons.plus, size: 18),
            ),
          ),
        );
      },
    );
  }

  Widget _initLoad(BuildContext context, String userId) {
    context.read<ExpenseListBloc>().add(ExpensesLoadRequested(userId: userId));
    return _skeleton();
  }

  Widget _skeleton() => ListView.builder(
        itemCount: 8,
        itemBuilder: (_, __) => const ExpenseTileSkeleton(),
      );

  Widget _list(
    BuildContext context,
    List<ExpenseEntity> expenses,
    String userId,
    double total,
  ) =>
      RefreshIndicator(
        color: AppColors.primary,
        backgroundColor: AppColors.surface,
        onRefresh: () async => context
            .read<ExpenseListBloc>()
            .add(ExpensesRefreshRequested(userId)),
        child: ListView.builder(
          itemCount: expenses.length + 1, // +1 for header
          itemBuilder: (ctx, i) {
            if (i == 0)
              return ExpenseListHeader(total: total, count: expenses.length);
            final expense = expenses[i - 1];
            return ExpenseTile(
              expense: expense,
              onTap: () => ctx.push('/expenses/${expense.id}', extra: expense),
              onDelete: () => ExpenseDeleteHelper.confirmAndDelete(ctx, expense),
            );
          },
        ),
      );
}

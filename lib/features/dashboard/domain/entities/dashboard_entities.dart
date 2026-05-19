import 'package:equatable/equatable.dart';
import '../../../expenses/domain/entities/expense_entity.dart';

/// Summary data shown on the dashboard home screen.
class DashboardSummaryEntity extends Equatable {
  final double totalThisMonth;
  final double totalLastMonth;
  final List<ExpenseEntity> recentExpenses;
  final Map<ExpenseCategory, double> categoryBreakdown;
  final List<MonthlyTrendPoint> monthlyTrend;

  const DashboardSummaryEntity({
    required this.totalThisMonth,
    required this.totalLastMonth,
    required this.recentExpenses,
    required this.categoryBreakdown,
    required this.monthlyTrend,
  });

  /// Percentage change vs last month. Positive = increase.
  double get monthOverMonthChange {
    if (totalLastMonth == 0) return 0;
    return ((totalThisMonth - totalLastMonth) / totalLastMonth) * 100;
  }

  bool get isIncreased => totalThisMonth > totalLastMonth;

  @override
  List<Object?> get props => [
        totalThisMonth,
        totalLastMonth,
        recentExpenses,
        categoryBreakdown,
        monthlyTrend,
      ];
}

/// A single data point on the monthly spending chart.
class MonthlyTrendPoint extends Equatable {
  final DateTime month;
  final double total;

  const MonthlyTrendPoint({required this.month, required this.total});

  @override
  List<Object?> get props => [month, total];
}

/// Analytics entity for category breakdown.
class CategoryBreakdownEntity extends Equatable {
  final ExpenseCategory category;
  final double total;
  final double percentage;
  final int count;

  const CategoryBreakdownEntity({
    required this.category,
    required this.total,
    required this.percentage,
    required this.count,
  });

  @override
  List<Object?> get props => [category, total, percentage, count];
}

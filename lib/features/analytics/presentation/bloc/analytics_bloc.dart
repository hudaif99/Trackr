import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../dashboard/domain/entities/dashboard_entities.dart';

// ── Events ──────────────────────────────────────────────────────────────────

sealed class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

final class AnalyticsLoadRequested extends AnalyticsEvent {
  final String userId;
  const AnalyticsLoadRequested(this.userId);
  @override
  List<Object?> get props => [userId];
}

// ── State ────────────────────────────────────────────────────────────────────

class AnalyticsSummary extends Equatable {
  final double totalThisMonth;
  final double averageMonthly;
  final ExpenseCategory topCategory;
  final int transactionCount;
  final List<CategoryBreakdownEntity> breakdown;
  final List<MonthlyTrendPoint> monthlyTrend;
  final List<WeeklyPoint> weeklyTrend;

  const AnalyticsSummary({
    required this.totalThisMonth,
    required this.averageMonthly,
    required this.topCategory,
    required this.transactionCount,
    required this.breakdown,
    required this.monthlyTrend,
    required this.weeklyTrend,
  });

  @override
  List<Object?> get props => [
        totalThisMonth,
        averageMonthly,
        topCategory,
        transactionCount,
        breakdown,
        monthlyTrend,
        weeklyTrend,
      ];
}

class WeeklyPoint extends Equatable {
  final String label; // "W1", "W2", etc.
  final double total;

  const WeeklyPoint({required this.label, required this.total});

  @override
  List<Object?> get props => [label, total];
}

sealed class AnalyticsState extends Equatable {
  const AnalyticsState();
  @override
  List<Object?> get props => [];
}

final class AnalyticsInitial extends AnalyticsState {
  const AnalyticsInitial();
}

final class AnalyticsLoading extends AnalyticsState {
  const AnalyticsLoading();
}

final class AnalyticsLoaded extends AnalyticsState {
  final AnalyticsSummary summary;
  const AnalyticsLoaded(this.summary);
  @override
  List<Object?> get props => [summary];
}

final class AnalyticsError extends AnalyticsState {
  final String message;
  const AnalyticsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────

/// Analytics BLoC that directly queries Firestore for efficiency.
/// 
/// Analytics is read-heavy and read-only — no need for a full repository layer
/// when a focused query service is cleaner and more performant.
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  final FirebaseFirestore _firestore;

  AnalyticsBloc(this._firestore) : super(const AnalyticsInitial()) {
    on<AnalyticsLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    AnalyticsLoadRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(const AnalyticsLoading());

    try {
      final now = DateTime.now();
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      final snap = await _firestore
          .collection(AppConstants.expensesCollection)
          .where('userId', isEqualTo: event.userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .get();

      final expenses = snap.docs
          .map((doc) => ExpenseModel.fromFirestore(doc))
          .toList();

      if (expenses.isEmpty) {
        emit(const AnalyticsError('No expense data yet.'));
        return;
      }

      emit(AnalyticsLoaded(_buildSummary(expenses, now)));
    } catch (e) {
      emit(AnalyticsError('Failed to load analytics: ${e.toString()}'));
    }
  }

  AnalyticsSummary _buildSummary(List<ExpenseModel> expenses, DateTime now) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonth = expenses.where((e) => !e.date.isBefore(thisMonthStart));
    final totalThisMonth = thisMonth.fold(0.0, (s, e) => s + e.amount);

    // Monthly totals
    final monthMap = <String, double>{};
    for (final e in expenses) {
      final k = '${e.date.year}-${e.date.month}';
      monthMap[k] = (monthMap[k] ?? 0) + e.amount;
    }
    final avgMonthly = monthMap.isEmpty
        ? 0.0
        : monthMap.values.fold(0.0, (s, v) => s + v) / monthMap.length;

    final trend = monthMap.entries
        .map((e) {
          final p = e.key.split('-');
          return MonthlyTrendPoint(
            month: DateTime(int.parse(p[0]), int.parse(p[1])),
            total: e.value,
          );
        })
        .toList()
      ..sort((a, b) => a.month.compareTo(b.month));

    // Category breakdown
    final catMap = <ExpenseCategory, double>{};
    final catCount = <ExpenseCategory, int>{};
    for (final e in thisMonth) {
      catMap[e.category] = (catMap[e.category] ?? 0) + e.amount;
      catCount[e.category] = (catCount[e.category] ?? 0) + 1;
    }
    final breakdown = catMap.entries
        .map((e) => CategoryBreakdownEntity(
              category: e.key,
              total: e.value,
              percentage: totalThisMonth > 0 ? (e.value / totalThisMonth) * 100 : 0,
              count: catCount[e.key] ?? 0,
            ))
        .toList()
      ..sort((a, b) => b.total.compareTo(a.total));

    final topCategory =
        breakdown.isNotEmpty ? breakdown.first.category : ExpenseCategory.other;

    // Weekly trend (current month)
    final weekMap = <int, double>{};
    for (final e in thisMonth) {
      final week = ((e.date.day - 1) ~/ 7) + 1;
      weekMap[week] = (weekMap[week] ?? 0) + e.amount;
    }
    final weekly = List.generate(
      4,
      (i) => WeeklyPoint(label: 'W${i + 1}', total: weekMap[i + 1] ?? 0),
    );

    return AnalyticsSummary(
      totalThisMonth: totalThisMonth,
      averageMonthly: avgMonthly,
      topCategory: topCategory,
      transactionCount: thisMonth.length,
      breakdown: breakdown,
      monthlyTrend: trend,
      weeklyTrend: weekly,
    );
  }
}

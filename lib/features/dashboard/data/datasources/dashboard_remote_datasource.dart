import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Aggregates expense data from Firestore to build the dashboard summary.
class DashboardRemoteDataSource {
  final FirebaseFirestore _firestore;

  const DashboardRemoteDataSource(this._firestore);

  Future<DashboardSummaryEntity> getDashboardSummary(String userId) async {
    try {
      final now = DateTime.now();
      final thisMonthStart = DateTime(now.year, now.month, 1);
      final lastMonthStart = DateTime(now.year, now.month - 1, 1);
      final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
      final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

      // Fetch last 6 months of data in one query
      final snap = await _firestore
          .collection(AppConstants.expensesCollection)
          .where('userId', isEqualTo: userId)
          .where('date',
              isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
          .orderBy('date', descending: true)
          .get();

      final expenses =
          snap.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();

      // ── This month ───────────────────────────────────────────────────────
      final thisMonth =
          expenses.where((e) => !e.date.isBefore(thisMonthStart)).toList();
      final totalThisMonth = thisMonth.fold(0.0, (s, e) => s + e.amount);

      // ── Last month ────────────────────────────────────────────────────────
      final lastMonth = expenses
          .where((e) =>
              !e.date.isBefore(lastMonthStart) && !e.date.isAfter(lastMonthEnd))
          .toList();
      final totalLastMonth = lastMonth.fold(0.0, (s, e) => s + e.amount);

      // ── Category breakdown (this month) ───────────────────────────────────
      final breakdown = <ExpenseCategory, double>{};
      for (final e in thisMonth) {
        breakdown[e.category] = (breakdown[e.category] ?? 0) + e.amount;
      }

      // ── Monthly trend (always 6 slots, 0 for months with no data) ────────
      // Build a map of all data keyed by 'yyyy-MM'
      final trendMap = <String, double>{};
      for (final e in expenses) {
        final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
        trendMap[key] = (trendMap[key] ?? 0) + e.amount;
      }
      // Generate all 6 month slots regardless of whether there is data
      final trend = List.generate(6, (i) {
        final month = DateTime(now.year, now.month - 5 + i);
        final key = '${month.year}-${month.month.toString().padLeft(2, '0')}';
        return MonthlyTrendPoint(month: month, total: trendMap[key] ?? 0);
      });

      return DashboardSummaryEntity(
        totalThisMonth: totalThisMonth,
        totalLastMonth: totalLastMonth,
        recentExpenses: expenses.take(5).toList(),
        categoryBreakdown: breakdown,
        monthlyTrend: trend,
      );
    } catch (e, stack) {
      log('--- FIRESTORE INDEX ERROR ---');
      log('Firebase provides a direct link to create the missing index:');
      log(e.toString());
      log('-----------------------------');
      throw ServerException('Failed to load dashboard: ${e.toString()}');
    }
  }
}

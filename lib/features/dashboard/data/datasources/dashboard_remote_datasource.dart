import 'dart:developer';

import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';

import '../../../../core/network/network_info.dart';
import '../../../expenses/data/datasources/expense_local_datasource.dart';
import '../../../expenses/data/models/expense_model.dart';
import '../../../expenses/domain/entities/expense_entity.dart';
import '../../domain/entities/dashboard_entities.dart';

/// Aggregates expense data to build the dashboard summary.
///
/// Online: queries Firestore directly for fresh data.
/// Offline: falls back to Hive local cache (includes pending unsynced items).
class DashboardRemoteDataSource {
  final FirebaseFirestore _firestore;
  final ExpenseLocalDataSource _local;
  final NetworkInfo _networkInfo;

  const DashboardRemoteDataSource(
    this._firestore,
    this._local,
    this._networkInfo,
  );

  Future<DashboardSummaryEntity> getDashboardSummary(String userId) async {
    if (await _networkInfo.isConnected) {
      try {
        return await _fetchFromFirestore(userId);
      } catch (e, stack) {
        log('--- FIRESTORE ERROR [DashboardRemoteDataSource] ---');
        log('Firebase provides a direct link to create any missing index:');
        log(e.toString());
        log(stack.toString());
        log('----------------------------------------------------');
        // Fall through to local cache on Firestore error.
      }
    }

    // Offline or Firestore error — build summary from Hive local cache.
    log('[DashboardRemoteDataSource] Building summary from local cache.');
    return _buildFromLocal(userId);
  }

  // ── Private ───────────────────────────────────────────────────────────────

  Future<DashboardSummaryEntity> _fetchFromFirestore(String userId) async {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final snap = await _firestore
        .collection(AppConstants.expensesCollection)
        .where('userId', isEqualTo: userId)
        .where('date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
        .orderBy('date', descending: true)
        .get();

    final expenses =
        snap.docs.map((doc) => ExpenseModel.fromFirestore(doc)).toList();

    // Also merge any locally pending (unsynced) items not yet on the server.
    final pending = _local
        .getExpenses(userId: userId)
        .where((e) => !e.isSynced)
        .toList();
    final remoteIds = expenses.map((e) => e.id).toSet();
    final allExpenses = <ExpenseModel>[
      ...expenses,
      ...pending
          .where((e) => !remoteIds.contains(e.id))
          .map((e) => ExpenseModel.fromEntity(e)),
    ]..sort((a, b) => b.date.compareTo(a.date));

    return _buildSummary(
      allExpenses,
      now,
      thisMonthStart,
      lastMonthStart,
      lastMonthEnd,
      sixMonthsAgo,
    );
  }

  DashboardSummaryEntity _buildFromLocal(String userId) {
    final now = DateTime.now();
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final lastMonthStart = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0, 23, 59, 59);
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final all = _local
        .getExpenses(userId: userId, from: sixMonthsAgo)
        .map((e) => ExpenseModel.fromEntity(e))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    return _buildSummary(
        all, now, thisMonthStart, lastMonthStart, lastMonthEnd, sixMonthsAgo);
  }

  DashboardSummaryEntity _buildSummary(
    List<ExpenseModel> expenses,
    DateTime now,
    DateTime thisMonthStart,
    DateTime lastMonthStart,
    DateTime lastMonthEnd,
    DateTime sixMonthsAgo,
  ) {
    // ── This month ─────────────────────────────────────────────────────────
    final thisMonth =
        expenses.where((e) => !e.date.isBefore(thisMonthStart)).toList();
    final totalThisMonth = thisMonth.fold(0.0, (s, e) => s + e.amount);

    // ── Last month ──────────────────────────────────────────────────────────
    final lastMonth = expenses
        .where((e) =>
            !e.date.isBefore(lastMonthStart) &&
            !e.date.isAfter(lastMonthEnd))
        .toList();
    final totalLastMonth = lastMonth.fold(0.0, (s, e) => s + e.amount);

    // ── Category breakdown (this month) ────────────────────────────────────
    final breakdown = <ExpenseCategory, double>{};
    for (final e in thisMonth) {
      breakdown[e.category] = (breakdown[e.category] ?? 0) + e.amount;
    }

    // ── Monthly trend (6 slots, 0 for months with no data) ─────────────────
    final trendMap = <String, double>{};
    for (final e in expenses) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}';
      trendMap[key] = (trendMap[key] ?? 0) + e.amount;
    }
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
  }
}

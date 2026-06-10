import 'dart:developer';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/network/network_info.dart';
import '../../../expenses/data/datasources/expense_local_datasource.dart';
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

final class AnalyticsEmpty extends AnalyticsState {
  const AnalyticsEmpty();
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
  final ExpenseLocalDataSource _local;
  final NetworkInfo _networkInfo;

  AnalyticsBloc(
    this._firestore,
    this._local,
    this._networkInfo,
  ) : super(const AnalyticsInitial()) {
    on<AnalyticsLoadRequested>(_onLoad);
  }

  Future<void> _onLoad(
    AnalyticsLoadRequested event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(const AnalyticsLoading());

    if (await _networkInfo.isConnected) {
      try {
        final now = DateTime.now();
        final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

        final snap = await _firestore
            .collection(AppConstants.expensesCollection)
            .where('userId', isEqualTo: event.userId)
            .where('date',
                isGreaterThanOrEqualTo: Timestamp.fromDate(sixMonthsAgo))
            .orderBy('date', descending: true)
            .get();

        final remote = snap.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList();

        // Merge any pending (unsynced) local items not yet on the server.
        final pending = _local
            .getExpenses(userId: event.userId)
            .where((e) => !e.isSynced)
            .toList();
        final remoteIds = remote.map((e) => e.id).toSet();
        final expenses = <ExpenseModel>[
          ...remote,
          ...pending
              .where((e) => !remoteIds.contains(e.id))
              .map((e) => ExpenseModel.fromEntity(e)),
        ]..sort((a, b) => b.date.compareTo(a.date));

        if (expenses.isEmpty) {
          emit(const AnalyticsEmpty());
          return;
        }

        emit(AnalyticsLoaded(_buildSummary(expenses, now)));
        return;
      } catch (e) {
        // ── INDEX ERROR HELPER ───────────────────────────────────────────────
        // Firebase prints a direct URL to create the missing index — look for
        // it in the logs below.
        log('\n══════ FIRESTORE ERROR [AnalyticsBloc] ══════');
        log(e.toString());
        log('══════════════════════════════════════════\n');
        // Fall through to local cache below.
      }
    }

    // Offline or Firestore error — build from local Hive cache.
    log('[AnalyticsBloc] Building from local cache.');
    _buildFromLocal(event.userId, emit);
  }

  void _buildFromLocal(String userId, Emitter<AnalyticsState> emit) {
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);

    final expenses = _local
        .getExpenses(userId: userId, from: sixMonthsAgo)
        .map((e) => ExpenseModel.fromEntity(e))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    if (expenses.isEmpty) {
      emit(const AnalyticsEmpty());
      return;
    }

    emit(AnalyticsLoaded(_buildSummary(expenses, now)));
  }

  AnalyticsSummary _buildSummary(List<ExpenseModel> expenses, DateTime now) {
    final thisMonthStart = DateTime(now.year, now.month, 1);
    final thisMonth = expenses.where((e) => !e.date.isBefore(thisMonthStart));
    final totalThisMonth = thisMonth.fold(0.0, (s, e) => s + e.amount);

    // Monthly totals — build a map keyed by 'yyyy-M'
    final monthMap = <String, double>{};
    for (final e in expenses) {
      final k = '${e.date.year}-${e.date.month}';
      monthMap[k] = (monthMap[k] ?? 0) + e.amount;
    }
    final avgMonthly = monthMap.isEmpty
        ? 0.0
        : monthMap.values.fold(0.0, (s, v) => s + v) / monthMap.length;

    // Always generate all 6 monthly slots — 0 for months with no data
    final trend = List.generate(6, (i) {
      final month = DateTime(now.year, now.month - 5 + i);
      final k = '${month.year}-${month.month}';
      return MonthlyTrendPoint(month: month, total: monthMap[k] ?? 0);
    });

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

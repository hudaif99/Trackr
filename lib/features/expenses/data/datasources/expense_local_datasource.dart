import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/expense_entity.dart';
import '../models/expense_model.dart';

/// Handles all Hive local storage operations for expenses.
///
/// Stores expenses by their ID as the key. This box is the source of
/// truth for offline mode and provides instant reads on app load.
class ExpenseLocalDataSource {
  Box<Map> get _box => Hive.box<Map>(AppConstants.expenseBox);

  // ── Read ──────────────────────────────────────────────────────────────────

  List<ExpenseModel> getExpenses({
    required String userId,
    String? category,
    DateTime? from,
    DateTime? to,
  }) {
    try {
      final all = _box.values
          .map((raw) => _fromMap(Map<String, dynamic>.from(raw)))
          .where((e) => e.userId == userId)
          .toList();

      return all
          .where((e) {
            if (category != null && e.category.name != category) return false;
            if (from != null && e.date.isBefore(from)) return false;
            if (to != null && e.date.isAfter(to)) return false;
            return true;
          })
          .toList()
        ..sort((a, b) => b.date.compareTo(a.date));
    } catch (e) {
      throw CacheException(message: 'Local read failed: ${e.toString()}');
    }
  }

  ExpenseModel? getExpenseById(String id) {
    try {
      final raw = _box.get(id);
      if (raw == null) return null;
      return _fromMap(Map<String, dynamic>.from(raw));
    } catch (e) {
      throw CacheException(message: 'Local read failed: ${e.toString()}');
    }
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<void> saveExpense(ExpenseEntity expense) async {
    try {
      await _box.put(expense.id, _toMap(expense));
    } catch (e) {
      throw CacheException(message: 'Local write failed: ${e.toString()}');
    }
  }

  Future<void> saveAll(List<ExpenseEntity> expenses) async {
    try {
      final map = {for (final e in expenses) e.id: _toMap(e)};
      await _box.putAll(map);
    } catch (e) {
      throw CacheException(message: 'Local write failed: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _box.delete(id);
    } catch (e) {
      throw CacheException(message: 'Local delete failed: ${e.toString()}');
    }
  }

  Future<void> clearUser(String userId) async {
    final keys = _box.keys.where((k) {
      final raw = _box.get(k);
      if (raw == null) return false;
      return raw['userId'] == userId;
    }).toList();
    await _box.deleteAll(keys);
  }

  // ── Serialisation helpers ─────────────────────────────────────────────────

  Map<String, dynamic> _toMap(ExpenseEntity e) => {
        'id': e.id,
        'userId': e.userId,
        'title': e.title,
        'amount': e.amount,
        'category': e.category.name,
        'date': e.date.millisecondsSinceEpoch,
        'note': e.note,
        'paymentMethod': e.paymentMethod.name,
        'createdAt': e.createdAt.millisecondsSinceEpoch,
        'isSynced': e.isSynced,
      };

  ExpenseModel _fromMap(Map<String, dynamic> m) => ExpenseModel(
        id: m['id'] as String,
        userId: m['userId'] as String,
        title: m['title'] as String,
        amount: (m['amount'] as num).toDouble(),
        category: ExpenseCategory.fromString(m['category'] as String),
        date: DateTime.fromMillisecondsSinceEpoch(m['date'] as int),
        note: m['note'] as String?,
        paymentMethod: PaymentMethod.fromString(
            m['paymentMethod'] as String? ?? 'cash'),
        createdAt:
            DateTime.fromMillisecondsSinceEpoch(m['createdAt'] as int),
        isSynced: m['isSynced'] as bool? ?? true,
      );
}

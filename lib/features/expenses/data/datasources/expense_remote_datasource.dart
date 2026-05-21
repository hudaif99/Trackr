import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/expense_entity.dart';
import '../models/expense_model.dart';

/// Handles all Firestore read/write operations for expenses.
class ExpenseRemoteDataSource {
  final FirebaseFirestore _firestore;

  const ExpenseRemoteDataSource(this._firestore);

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(AppConstants.expensesCollection);

  // ── Read ──────────────────────────────────────────────────────────────────

  Future<List<ExpenseModel>> getExpenses({
    required String userId,
    String? category,
    DateTime? from,
    DateTime? to,
    int limit = 50,
  }) async {
    try {
      // Build all where() clauses BEFORE orderBy() — Firestore requires this
      // order to avoid the failed-precondition / missing composite-index error.
      Query<Map<String, dynamic>> query =
          _collection.where('userId', isEqualTo: userId);

      if (category != null) {
        query = query.where('category', isEqualTo: category);
      }
      if (from != null) {
        query = query.where(
            'date', isGreaterThanOrEqualTo: Timestamp.fromDate(from));
      }
      if (to != null) {
        query =
            query.where('date', isLessThanOrEqualTo: Timestamp.fromDate(to));
      }

      query = query.orderBy('date', descending: true).limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ExpenseModel.fromFirestore(
              doc as DocumentSnapshot<Map<String, dynamic>>))
          .toList();
    } catch (e) {
      // ── INDEX ERROR HELPER ─────────────────────────────────────────────────
      // If this is a Firestore index error, Firebase prints a direct URL below
      // that auto-creates the missing index. Copy-paste it into your browser.
      // ignore: avoid_print
      print('\n══════════ FIRESTORE ERROR [getExpenses] ══════════');
      // ignore: avoid_print
      print(e.toString());
      // ignore: avoid_print
      print('═══════════════════════════════════════════════════\n');
      throw ServerException('Failed to fetch expenses: ${e.toString()}');
    }
  }

  Future<ExpenseModel?> getExpenseById(String id) async {
    try {
      final doc = await _collection.doc(id).get();
      if (!doc.exists) return null;
      return ExpenseModel.fromFirestore(doc);
    } catch (e) {
      throw ServerException('Failed to fetch expense: ${e.toString()}');
    }
  }

  Stream<List<ExpenseModel>> watchExpenses(String userId) {
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ExpenseModel.fromFirestore(doc))
            .toList());
  }

  // ── Write ─────────────────────────────────────────────────────────────────

  Future<ExpenseModel> createExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await _collection.doc(model.id).set(model.toFirestore());
      return model;
    } catch (e) {
      throw ServerException('Failed to create expense: ${e.toString()}');
    }
  }

  Future<ExpenseModel> updateExpense(ExpenseEntity expense) async {
    try {
      final model = ExpenseModel.fromEntity(expense);
      await _collection.doc(model.id).update(model.toFirestore());
      return model;
    } catch (e) {
      throw ServerException('Failed to update expense: ${e.toString()}');
    }
  }

  Future<void> deleteExpense(String id) async {
    try {
      await _collection.doc(id).delete();
    } catch (e) {
      throw ServerException('Failed to delete expense: ${e.toString()}');
    }
  }
}

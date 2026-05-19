import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/expense_entity.dart';

/// Data model that handles Firestore serialisation.
///
/// Extends [ExpenseEntity] so the domain/presentation layer can use it
/// transparently. Hive storage uses manual Map serialization in
/// [ExpenseLocalDataSource] — no code-gen required.
class ExpenseModel extends ExpenseEntity {
  const ExpenseModel({
    required super.id,
    required super.userId,
    required super.title,
    required super.amount,
    required super.category,
    required super.date,
    super.note,
    required super.paymentMethod,
    required super.createdAt,
    super.isSynced,
  });

  // ── Factory constructors ──────────────────────────────────────────────────

  factory ExpenseModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return ExpenseModel(
      id: doc.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      amount: (data['amount'] as num).toDouble(),
      category: ExpenseCategory.fromString(data['category'] as String),
      date: (data['date'] as Timestamp).toDate(),
      note: data['note'] as String?,
      paymentMethod:
          PaymentMethod.fromString(data['paymentMethod'] as String? ?? 'cash'),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isSynced: true,
    );
  }

  factory ExpenseModel.fromEntity(ExpenseEntity entity) => ExpenseModel(
        id: entity.id,
        userId: entity.userId,
        title: entity.title,
        amount: entity.amount,
        category: entity.category,
        date: entity.date,
        note: entity.note,
        paymentMethod: entity.paymentMethod,
        createdAt: entity.createdAt,
        isSynced: entity.isSynced,
      );

  // ── Serialisation ──────────────────────────────────────────────────────────

  /// Maps to the Firestore schema:
  /// expenses/{id} → userId, title, amount, category, note,
  ///                  date, paymentMethod, createdAt
  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'title': title,
        'amount': amount,
        'category': category.name,
        'date': Timestamp.fromDate(date),
        'note': note,
        'paymentMethod': paymentMethod.name,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

import 'package:equatable/equatable.dart';

/// Expense categories supported by Trackr.
enum ExpenseCategory {
  food,
  travel,
  shopping,
  bills,
  entertainment,
  health,
  fuel,
  education,
  other;

  String get displayName => switch (this) {
        food => 'Food',
        travel => 'Travel',
        shopping => 'Shopping',
        bills => 'Bills',
        entertainment => 'Entertainment',
        health => 'Health',
        fuel => 'Fuel',
        education => 'Education',
        other => 'Other',
      };

  String get emoji => switch (this) {
        food => '🍔',
        travel => '✈️',
        shopping => '🛍️',
        bills => '📄',
        entertainment => '🎬',
        health => '❤️',
        fuel => '⛽',
        education => '📚',
        other => '📦',
      };

  /// Parses a string to [ExpenseCategory], case-insensitive. Defaults to [other].
  static ExpenseCategory fromString(String value) {
    return ExpenseCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == value.toLowerCase(),
      orElse: () => other,
    );
  }
}

/// Payment method options.
enum PaymentMethod {
  cash,
  card,
  upi,
  netBanking,
  wallet;

  String get displayName => switch (this) {
        cash => 'Cash',
        card => 'Card',
        upi => 'UPI',
        netBanking => 'Net Banking',
        wallet => 'Wallet',
      };

  static PaymentMethod fromString(String value) {
    return PaymentMethod.values.firstWhere(
      (m) => m.name.toLowerCase() == value.toLowerCase(),
      orElse: () => cash,
    );
  }
}

/// Core domain entity representing a single expense.
///
/// Immutable — use [copyWith] to create modified copies.
class ExpenseEntity extends Equatable {
  final String id;
  final String userId;
  final String title;
  final double amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? note;
  final PaymentMethod paymentMethod;
  final DateTime createdAt;

  /// True once the record has been successfully written to Firestore.
  /// Used to show an offline indicator in the UI.
  final bool isSynced;

  const ExpenseEntity({
    required this.id,
    required this.userId,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
    this.note,
    required this.paymentMethod,
    required this.createdAt,
    this.isSynced = true,
  });

  ExpenseEntity copyWith({
    String? title,
    double? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? note,
    PaymentMethod? paymentMethod,
    bool? isSynced,
  }) =>
      ExpenseEntity(
        id: id,
        userId: userId,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        category: category ?? this.category,
        date: date ?? this.date,
        note: note ?? this.note,
        paymentMethod: paymentMethod ?? this.paymentMethod,
        createdAt: createdAt,
        isSynced: isSynced ?? this.isSynced,
      );

  @override
  List<Object?> get props => [
        id,
        userId,
        title,
        amount,
        category,
        date,
        note,
        paymentMethod,
        createdAt,
        isSynced,
      ];
}

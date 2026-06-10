import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../ai/presentation/bloc/ai_categorization_cubit.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../domain/entities/expense_entity.dart';
import '../bloc/expense_bloc.dart';
import '../widgets/ai_categorization_icon.dart';
import '../widgets/expense_category_selector.dart';
import '../widgets/expense_date_picker_button.dart';
import '../widgets/expense_payment_method_selector.dart';

/// Screen for adding a new expense.
///
/// Includes AI-powered auto-categorization with 800ms debounce.
class AddExpensePage extends StatefulWidget {
  const AddExpensePage({super.key});

  @override
  State<AddExpensePage> createState() => _AddExpensePageState();
}

class _AddExpensePageState extends State<AddExpensePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  ExpenseCategory _category = ExpenseCategory.other;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  DateTime _date = DateTime.now();
  Timer? _debounce;

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onTitleChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(AppConstants.aiDebounce, () {
      if (value.trim().length >= 3) {
        context.read<AiCategorizationCubit>().categorize(value);
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    final expense = ExpenseEntity(
      id: const Uuid().v4(),
      userId: authState.user.uid,
      title: _titleController.text.trim(),
      amount: double.parse(_amountController.text.trim()),
      category: _category,
      date: _date,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      paymentMethod: _paymentMethod,
      createdAt: DateTime.now(),
    );

    context.read<ExpenseFormBloc>().add(ExpenseFormSubmitted(expense));
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<ExpenseFormBloc, ExpenseFormState>(
          listener: (context, state) {
            if (state is ExpenseFormSuccess) {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppConstants.routeDashboard);
              }
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Expense added ✓'),
                  backgroundColor: AppColors.primary,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            } else if (state is ExpenseFormFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppColors.expense,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
        ),
        BlocListener<AiCategorizationCubit, AiCategorizationState>(
          listener: (context, state) {
            if (state is AiCategorizationSuccess) {
              setState(() => _category = state.category);
            }
          },
        ),
      ],
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Add Expense'),
          leading: IconButton(
            icon: const FaIcon(FontAwesomeIcons.xmark, size: 18),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppConstants.routeDashboard);
              }
            },
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Title with AI indicator ────────────────────────────────
              BlocBuilder<AiCategorizationCubit, AiCategorizationState>(
                builder: (context, aiState) {
                  return AppTextField(
                    label: 'What did you spend on?',
                    hint: 'e.g. KFC dinner, Petrol, Netflix',
                    controller: _titleController,
                    onChanged: _onTitleChanged,
                    textInputAction: TextInputAction.next,
                    suffixIcon: (aiState is AiCategorizationLoading ||
                            aiState is AiCategorizationSuccess)
                        ? AiCategorizationIcon(state: aiState)
                        : null,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  );
                },
              ),
              const SizedBox(height: 16),

              // ── Amount ─────────────────────────────────────────────────
              AppTextField(
                label: 'Amount (₹)',
                hint: '0.00',
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))
                ],
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.currency_rupee_rounded,
                    color: AppColors.textSecondary, size: 20),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  final d = double.tryParse(v);
                  if (d == null || d <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // ── Category chips ─────────────────────────────────────────
              ExpenseCategorySelector(
                selectedCategory: _category,
                onChanged: (cat) => setState(() => _category = cat),
              ),
              const SizedBox(height: 20),

              // ── Date ───────────────────────────────────────────────────
              ExpenseDatePickerButton(
                selectedDate: _date,
                onTap: _pickDate,
              ),
              const SizedBox(height: 20),

              // ── Payment method ─────────────────────────────────────────
              ExpensePaymentMethodSelector(
                selectedMethod: _paymentMethod,
                onChanged: (m) => setState(() => _paymentMethod = m),
              ),
              const SizedBox(height: 20),

              // ── Note ───────────────────────────────────────────────────
              AppTextField(
                label: 'Note (optional)',
                hint: 'Add a note...',
                controller: _noteController,
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 32),

              // ── Submit ─────────────────────────────────────────────────
              BlocBuilder<ExpenseFormBloc, ExpenseFormState>(
                builder: (context, state) => AppButton(
                  label: 'Save Expense',
                  isLoading: state is ExpenseFormSubmitting,
                  onPressed: _submit,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.primary,
            surface: AppColors.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }
}

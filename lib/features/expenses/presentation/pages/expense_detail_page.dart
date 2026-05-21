import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/extensions/double_x.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/expense_entity.dart';

/// Full-screen detail view for a single expense.
class ExpenseDetailPage extends StatelessWidget {
  final ExpenseEntity expense;

  const ExpenseDetailPage({super.key, required this.expense});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Collapsing hero header ───────────────────────────────────────
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: IconButton(
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 18),
              onPressed: () => context.go(AppConstants.routeExpenses),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: _HeroHeader(expense: expense),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Details card ─────────────────────────────────────────
                  _DetailCard(expense: expense),
                  const SizedBox(height: 20),

                  // ── Note card ────────────────────────────────────────────
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    _NoteCard(note: expense.note!),
                    const SizedBox(height: 20),
                  ],

                  // ── Meta card ─────────────────────────────────────────────
                  _MetaCard(expense: expense),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero Header ───────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final ExpenseEntity expense;

  const _HeroHeader({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF0D9E6E), Color(0xFF0E7490)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -30,
            top: -30,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Positioned.fill(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40), // account for app bar
                Text(
                  expense.category.emoji,
                  style: const TextStyle(fontSize: 40),
                ),
                const SizedBox(height: 8),
                Text(
                  expense.amount.inr,
                  style: AppTextStyles.amountHero.copyWith(
                    color: Colors.white,
                    fontSize: 40,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.title,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Detail Card ───────────────────────────────────────────────────────────────

class _DetailCard extends StatelessWidget {
  final ExpenseEntity expense;

  const _DetailCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _Row(
            icon: FontAwesomeIcons.tag,
            label: 'Category',
            value: '${expense.category.emoji}  ${expense.category.displayName}',
          ),
          _Divider(),
          _Row(
            icon: FontAwesomeIcons.calendarDays,
            label: 'Date',
            value: _fullDate(expense.date),
          ),
          _Divider(),
          _Row(
            icon: FontAwesomeIcons.creditCard,
            label: 'Payment',
            value: expense.paymentMethod.displayName,
          ),
        ],
      ),
    );
  }

  String _fullDate(DateTime d) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Note Card ─────────────────────────────────────────────────────────────────

class _NoteCard extends StatelessWidget {
  final String note;

  const _NoteCard({required this.note});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const FaIcon(FontAwesomeIcons.noteSticky,
                  size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 8),
              Text('Note',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.textSecondary,
                  )),
            ],
          ),
          const SizedBox(height: 8),
          Text(note, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

// ── Meta Card ─────────────────────────────────────────────────────────────────

class _MetaCard extends StatelessWidget {
  final ExpenseEntity expense;

  const _MetaCard({required this.expense});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _Row(
            icon: FontAwesomeIcons.hashtag,
            label: 'Expense ID',
            value: expense.id.substring(0, 8).toUpperCase(),
            onTap: () {
              Clipboard.setData(ClipboardData(text: expense.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('ID copied to clipboard'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          _Divider(),
          _Row(
            icon: FontAwesomeIcons.rotateRight,
            label: 'Sync status',
            value: expense.isSynced ? 'Synced ✓' : 'Pending sync',
            valueColor:
                expense.isSynced ? AppColors.primary : AppColors.warning,
          ),
        ],
      ),
    );
  }
}

// ── Shared Widgets ────────────────────────────────────────────────────────────

class _Row extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback? onTap;

  const _Row({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: FaIcon(icon, size: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(width: 12),
            Text(label, style: AppTextStyles.bodySmall),
            const Spacer(),
            Text(
              value,
              style: AppTextStyles.titleSmall.copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
            if (onTap != null) ...[
              const SizedBox(width: 4),
              const FaIcon(FontAwesomeIcons.copy,
                  size: 12, color: AppColors.textDisabled),
            ],
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      indent: 60,
      color: AppColors.divider,
    );
  }
}

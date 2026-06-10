import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/expense_entity.dart';
import "../widgets/expense_detail_card.dart";
import "../widgets/expense_hero_header.dart";
import "../widgets/expense_meta_card.dart";
import "../widgets/expense_note_card.dart";

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
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppConstants.routeDashboard);
                }
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ExpenseHeroHeader(expense: expense),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Details card ─────────────────────────────────────────
                  ExpenseDetailCard(expense: expense),
                  const SizedBox(height: 20),

                  // ── Note card ────────────────────────────────────────────
                  if (expense.note != null && expense.note!.isNotEmpty) ...[
                    ExpenseNoteCard(note: expense.note!),
                    const SizedBox(height: 20),
                  ],

                  // ── Meta card ─────────────────────────────────────────────
                  ExpenseMetaCard(expense: expense),
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

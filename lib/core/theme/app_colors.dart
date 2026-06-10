import 'package:flutter/material.dart';

/// Centralized color palette for Trackr.
/// Dark-first fintech design — all colors are intentional and curated.
abstract final class AppColors {
  // ── Backgrounds ──────────────────────────────────────────────────────────
  static const Color background = Color(0xFF0F172A);
  static const Color surface = Color(0xFF111827);
  static const Color surfaceVariant = Color(0xFF1E293B);
  static const Color cardBorder = Color(0xFF1E293B);

  // ── Brand ─────────────────────────────────────────────────────────────────
  static const Color primary = Color(0xFF10B981);
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);
  static const Color accent = Color(0xFF22D3EE);

  // ── Semantic ──────────────────────────────────────────────────────────────
  static const Color expense = Color(0xFFF43F5E);
  static const Color expenseLight = Color(0xFFFDA4AF);
  static const Color income = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF3B82F6);

  // ── Text ──────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF475569);
  static const Color textInverse = Color(0xFF0F172A);

  // ── Light theme overrides ──────────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);

  // ── Category colors ───────────────────────────────────────────────────────
  static const Color catFood = Color(0xFFF97316);
  static const Color catTravel = Color(0xFF3B82F6);
  static const Color catShopping = Color(0xFFA855F7);
  static const Color catBills = Color(0xFFF43F5E);
  static const Color catEntertainment = Color(0xFFEC4899);
  static const Color catHealth = Color(0xFF10B981);
  static const Color catFuel = Color(0xFFF59E0B);
  static const Color catEducation = Color(0xFF06B6D4);
  static const Color catOther = Color(0xFF64748B);

  // ── Divider / Border ──────────────────────────────────────────────────────
  static const Color divider = Color(0xFF1E293B);
  static const Color border = Color(0xFF334155);

  // ── Gradients ─────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, accent],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [background, surface],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

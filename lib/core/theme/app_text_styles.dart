import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Typography scale using Inter (via Google Fonts).
/// All sizes use logical pixels — flutter_screenutil adapts them at runtime.
abstract final class AppTextStyles {
  static TextStyle _base({
    required double fontSize,
    required FontWeight weight,
    Color color = AppColors.textPrimary,
    double? letterSpacing,
    double? height,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: weight,
        color: color,
        letterSpacing: letterSpacing,
        height: height,
      );

  // ── Display ───────────────────────────────────────────────────────────────
  static TextStyle get displayLarge => _base(
        fontSize: 48,
        weight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1.1,
      );

  static TextStyle get displayMedium => _base(
        fontSize: 36,
        weight: FontWeight.w700,
        letterSpacing: -1.0,
        height: 1.15,
      );

  // ── Headline ──────────────────────────────────────────────────────────────
  static TextStyle get headlineLarge => _base(
        fontSize: 28,
        weight: FontWeight.w700,
        letterSpacing: -0.5,
        height: 1.2,
      );

  static TextStyle get headlineMedium => _base(
        fontSize: 22,
        weight: FontWeight.w600,
        letterSpacing: -0.3,
        height: 1.3,
      );

  static TextStyle get headlineSmall => _base(
        fontSize: 18,
        weight: FontWeight.w600,
        height: 1.35,
      );

  // ── Title ─────────────────────────────────────────────────────────────────
  static TextStyle get titleLarge => _base(
        fontSize: 16,
        weight: FontWeight.w600,
        height: 1.4,
      );

  static TextStyle get titleMedium => _base(
        fontSize: 14,
        weight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      );

  static TextStyle get titleSmall => _base(
        fontSize: 12,
        weight: FontWeight.w600,
        height: 1.4,
        letterSpacing: 0.1,
      );

  // ── Body ──────────────────────────────────────────────────────────────────
  static TextStyle get bodyLarge => _base(
        fontSize: 16,
        weight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodyMedium => _base(
        fontSize: 14,
        weight: FontWeight.w400,
        height: 1.5,
      );

  static TextStyle get bodySmall => _base(
        fontSize: 12,
        weight: FontWeight.w400,
        color: AppColors.textSecondary,
        height: 1.5,
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  static TextStyle get labelLarge => _base(
        fontSize: 14,
        weight: FontWeight.w500,
        letterSpacing: 0.1,
      );

  static TextStyle get labelMedium => _base(
        fontSize: 12,
        weight: FontWeight.w500,
        letterSpacing: 0.5,
      );

  static TextStyle get labelSmall => _base(
        fontSize: 10,
        weight: FontWeight.w500,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      );

  // ── Amount (fintech-specific) ─────────────────────────────────────────────
  static TextStyle get amountHero => _base(
        fontSize: 42,
        weight: FontWeight.w700,
        color: AppColors.textPrimary,
        letterSpacing: -1.0,
        height: 1.0,
      );

  static TextStyle get amountLarge => _base(
        fontSize: 24,
        weight: FontWeight.w700,
        letterSpacing: -0.5,
      );

  static TextStyle get amountMedium => _base(
        fontSize: 18,
        weight: FontWeight.w600,
      );

  static TextStyle get amountSmall => _base(
        fontSize: 14,
        weight: FontWeight.w600,
      );
}

import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

extension BuildContextX on BuildContext {
  // ── Theme shortcuts ───────────────────────────────────────────────────────
  ThemeData get theme => Theme.of(this);
  ColorScheme get colorScheme => Theme.of(this).colorScheme;
  TextTheme get textTheme => Theme.of(this).textTheme;

  // ── Color shortcuts ───────────────────────────────────────────────────────
  Color get primaryColor => colorScheme.primary;
  Color get backgroundColor => colorScheme.surface;
  Color get errorColor => colorScheme.error;

  // ── AppColors shortcut ────────────────────────────────────────────────────
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Responsive helpers ────────────────────────────────────────────────────
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  bool get isTablet => screenWidth >= 600;

  // ── Navigation ────────────────────────────────────────────────────────────
  void pop<T>([T? result]) => Navigator.of(this).pop(result);

  // ── SnackBar helpers ──────────────────────────────────────────────────────
  void showSuccessSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.primary.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void showErrorSnack(String message) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message, style: AppTextStyles.bodyMedium),
        backgroundColor: AppColors.expense.withOpacity(0.9),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

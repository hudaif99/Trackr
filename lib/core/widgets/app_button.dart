import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// Primary, full-width elevated button with loading state support.
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final Widget? icon;
  final Color? backgroundColor;
  final double? width;
  final double height;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.icon,
    this.backgroundColor,
    this.width,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: Colors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[icon!, const SizedBox(width: 8)],
              Text(label, style: AppTextStyles.labelLarge),
            ],
          );

    final buttonStyle = isOutlined
        ? OutlinedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height),
            foregroundColor: AppColors.primary,
          )
        : ElevatedButton.styleFrom(
            minimumSize: Size(width ?? double.infinity, height),
            backgroundColor: backgroundColor ?? AppColors.primary,
            foregroundColor: AppColors.textInverse,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
          );

    return isOutlined
        ? OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: child,
          )
        : ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: buttonStyle,
            child: child,
          );
  }
}

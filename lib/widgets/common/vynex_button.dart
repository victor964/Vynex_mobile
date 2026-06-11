// Reusable button widget with primary, secondary, and danger variants.

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Button style variants for Vynex actions.
enum VynexButtonVariant { primary, secondary, danger }

/// A reusable styled button for Vynex forms and actions.
class VynexButton extends StatelessWidget {
  /// Creates a Vynex button.
  const VynexButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = VynexButtonVariant.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  });

  /// Gold background primary button.
  const VynexButton.primary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  }) : variant = VynexButtonVariant.primary;

  /// Gold border secondary button.
  const VynexButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  }) : variant = VynexButtonVariant.secondary;

  /// Red destructive button.
  const VynexButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.icon,
  }) : variant = VynexButtonVariant.danger;

  final String label;
  final VoidCallback? onPressed;
  final VynexButtonVariant variant;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == VynexButtonVariant.primary
                  ? AppColors.black
                  : AppColors.white,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 20),
                const SizedBox(width: 8),
              ],
              Text(label),
            ],
          );

    const minimumSize = Size(0, 52);

    final Widget button;
    switch (variant) {
      case VynexButtonVariant.primary:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            minimumSize: minimumSize,
          ),
          child: child,
        );
      case VynexButtonVariant.secondary:
        button = OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            minimumSize: minimumSize,
          ),
          child: child,
        );
      case VynexButtonVariant.danger:
        button = ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.danger,
            foregroundColor: AppColors.white,
            minimumSize: minimumSize,
            elevation: 0,
          ),
          child: child,
        );
    }

    if (!isFullWidth) {
      return button;
    }

    return SizedBox(
      width: double.infinity,
      child: button,
    );
  }
}

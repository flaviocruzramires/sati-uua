import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.block = false,
    this.loading = false,
    this.centerLabel = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool block;
  final bool loading;
  final bool centerLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = loading ? null : onPressed;

    Widget child = _buildChild(context);
    if (block) child = SizedBox(width: double.infinity, child: child);

    return switch (variant) {
      AppButtonVariant.primary => ElevatedButton(
        onPressed: effectiveOnPressed,
        style: ElevatedButton.styleFrom(
          alignment: centerLabel ? Alignment.center : Alignment.centerLeft,
        ),
        child: child,
      ),
      AppButtonVariant.secondary => OutlinedButton(
        onPressed: effectiveOnPressed,
        style: OutlinedButton.styleFrom(
          alignment: centerLabel ? Alignment.center : Alignment.centerLeft,
        ),
        child: child,
      ),
      AppButtonVariant.ghost => TextButton(
        onPressed: effectiveOnPressed,
        style: TextButton.styleFrom(
          alignment: centerLabel ? Alignment.center : Alignment.centerLeft,
        ),
        child: child,
      ),
    };
  }

  Widget _buildChild(BuildContext context) {
    if (loading) {
      return SizedBox(
        height: 18,
        width: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: variant == AppButtonVariant.primary
              ? AppColors.bg
              : AppColors.navy,
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16),
          const SizedBox(width: AppSpacing.s2),
          Text(label),
        ],
      );
    }

    return Text(label);
  }
}

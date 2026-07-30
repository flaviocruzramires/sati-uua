import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class IconActionButton extends StatelessWidget {
  const IconActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.neutral300),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          foregroundColor: AppColors.neutral700,
          alignment: Alignment.center,
        ),
        child: Icon(icon, size: 16),
      ),
    );

    if (tooltip != null) return Tooltip(message: tooltip!, child: btn);
    return btn;
  }
}

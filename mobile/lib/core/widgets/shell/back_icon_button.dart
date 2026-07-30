import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';

class BackIconButton extends StatelessWidget {
  const BackIconButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 36,
      child: OutlinedButton(
        onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          side: const BorderSide(color: AppColors.neutral300),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          foregroundColor: AppColors.neutral700,
          alignment: Alignment.center,
        ),
        child: const Icon(LucideIcons.arrowLeft, size: 16),
      ),
    );
  }
}

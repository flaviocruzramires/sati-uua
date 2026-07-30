import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.mensagem, this.icon});

  final String mensagem;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon ?? LucideIcons.inbox,
              size: 40,
              color: AppColors.neutral400,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

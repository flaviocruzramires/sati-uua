import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../actions/app_button.dart';

class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.mensagem, this.onRetry});

  final String mensagem;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.alertCircle, size: 40, color: Colors.red),
            const SizedBox(height: AppSpacing.s4),
            Text(
              mensagem,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.s6),
              AppButton(
                label: 'Tentar novamente',
                onPressed: onRetry,
                variant: AppButtonVariant.secondary,
                centerLabel: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

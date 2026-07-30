import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../surfaces/app_card.dart';

class AppCardListItem extends StatelessWidget {
  const AppCardListItem({
    super.key,
    required this.titulo,
    this.tagSlot,
    this.metaLines = const [],
    this.onTap,
  });

  final String titulo;
  final Widget? tagSlot;
  final List<String> metaLines;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AppCard(
        elevation: AppCardElevation.sm,
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (metaLines.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.s1),
                    ...metaLines.map((m) => Text(
                          m,
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: AppColors.muted),
                        )),
                  ],
                ],
              ),
            ),
            if (tagSlot != null) ...[
              const SizedBox(width: AppSpacing.s2),
              tagSlot!,
            ],
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../domain/enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class SidebarNavItem extends StatelessWidget {
  const SidebarNavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.visibleForPapeis = const [],
    this.currentPapel,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final List<PapelUsuario> visibleForPapeis;
  final PapelUsuario? currentPapel;

  bool get _visible =>
      visibleForPapeis.isEmpty ||
      (currentPapel != null && visibleForPapeis.contains(currentPapel));

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: active ? AppColors.navy : Colors.transparent,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s3,
          vertical: 10,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: active ? AppColors.bg : AppColors.neutral600,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? AppColors.bg : AppColors.text,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SidebarNavGroup extends StatelessWidget {
  const SidebarNavGroup({
    super.key,
    required this.label,
    required this.children,
  });

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s3,
            AppSpacing.s4,
            AppSpacing.s3,
            AppSpacing.s2,
          ),
          child: Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.08 * 10,
              color: AppColors.neutral600,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

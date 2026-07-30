import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../formatters/paginacao_formatter.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class PaginationBar extends StatelessWidget {
  const PaginationBar({
    super.key,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.onPageChanged,
  });

  final int page;
  final int pageSize;
  final int total;
  final ValueChanged<int> onPageChanged;

  int get _lastPage => ((total - 1) / pageSize).floor() + 1;

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    final last = _lastPage;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      child: Row(
        children: [
          Text(
            paginacaoLabel(page, pageSize, total),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
          ),
          const Spacer(),
          _PgBtn(
            icon: LucideIcons.chevronLeft,
            enabled: page > 1,
            onTap: () => onPageChanged(page - 1),
          ),
          ..._pageNumbers(last).map(
            (n) => n == null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '…',
                      style: Theme.of(
                        context,
                      ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                    ),
                  )
                : _PgBtn(
                    label: '$n',
                    active: n == page,
                    onTap: () => onPageChanged(n),
                  ),
          ),
          _PgBtn(
            icon: LucideIcons.chevronRight,
            enabled: page < last,
            onTap: () => onPageChanged(page + 1),
          ),
        ],
      ),
    );
  }

  List<int?> _pageNumbers(int last) {
    if (last <= 7) return List.generate(last, (i) => i + 1);
    if (page <= 4) return [1, 2, 3, 4, 5, null, last];
    if (page >= last - 3) {
      return [1, null, last - 4, last - 3, last - 2, last - 1, last];
    }
    return [1, null, page - 1, page, page + 1, null, last];
  }
}

class _PgBtn extends StatelessWidget {
  const _PgBtn({
    this.label,
    this.icon,
    this.active = false,
    this.enabled = true,
    required this.onTap,
  });

  final String? label;
  final IconData? icon;
  final bool active;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bg = active ? AppColors.navy : Colors.transparent;
    final fg = active
        ? AppColors.bg
        : enabled
        ? AppColors.text
        : AppColors.neutral400;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(
            color: active ? AppColors.navy : AppColors.neutral300,
          ),
        ),
        alignment: Alignment.center,
        child: icon != null
            ? Icon(icon, size: 14, color: fg)
            : Text(
                label!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: fg, fontSize: 12),
              ),
      ),
    );
  }
}

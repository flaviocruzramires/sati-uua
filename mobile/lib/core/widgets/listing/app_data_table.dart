import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';

class AppDataTable<T> extends StatelessWidget {
  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    required this.rowBuilder,
    this.onRowTap,
    this.actionsBuilder,
  });

  final List<String> columns;
  final List<T> rows;
  final List<Widget> Function(T item) rowBuilder;
  final ValueChanged<T>? onRowTap;
  final List<Widget> Function(T item)? actionsBuilder;

  @override
  Widget build(BuildContext context) {
    final allColumns = [...columns, if (actionsBuilder != null) 'Ações'];

    return Table(
      border: TableBorder.all(color: AppColors.neutral300, width: 1),
      columnWidths: _columnWidths(allColumns.length),
      children: [
        _headerRow(context, allColumns),
        ...rows.map((item) => _dataRow(context, item)),
      ],
    );
  }

  Map<int, TableColumnWidth> _columnWidths(int count) {
    if (actionsBuilder == null) return {};
    return {count - 1: const FixedColumnWidth(100)};
  }

  TableRow _headerRow(BuildContext context, List<String> cols) {
    return TableRow(
      decoration: const BoxDecoration(color: AppColors.surface),
      children: cols
          .map(
            (col) => _Cell(
              child: Text(col, style: Theme.of(context).textTheme.titleSmall),
            ),
          )
          .toList(),
    );
  }

  TableRow _dataRow(BuildContext context, T item) {
    final cells = rowBuilder(item);
    return TableRow(
      decoration: BoxDecoration(color: AppColors.bg),
      children: [
        ...cells.map(
          (c) => GestureDetector(
            onTap: onRowTap != null ? () => onRowTap!(item) : null,
            child: _Cell(child: c),
          ),
        ),
        if (actionsBuilder != null)
          _Cell(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: actionsBuilder!(item),
            ),
          ),
      ],
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      child: child,
    );
  }
}

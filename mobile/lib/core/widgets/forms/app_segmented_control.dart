import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class SegmentedOption<T> {
  final T value;
  final String label;
  const SegmentedOption(this.value, this.label);
}

class AppSegmentedControl<T> extends StatelessWidget {
  const AppSegmentedControl({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.fullWidth = false,
  });

  final List<SegmentedOption<T>> options;
  final T value;
  final ValueChanged<T> onChanged;
  final bool fullWidth;

  @override
  Widget build(BuildContext context) {
    final row = Row(
      mainAxisSize: fullWidth ? MainAxisSize.max : MainAxisSize.min,
      children: options.map((opt) {
        final selected = opt.value == value;
        return Flexible(
          flex: fullWidth ? 1 : 0,
          child: GestureDetector(
            onTap: () => onChanged(opt.value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? AppColors.navy : AppColors.surface,
                border: Border.all(color: AppColors.neutral300),
              ),
              alignment: Alignment.center,
              child: Text(
                opt.label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: selected ? AppColors.bg : AppColors.text,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ),
          ),
        );
      }).toList(),
    );

    if (fullWidth) return row;
    return IntrinsicWidth(child: row);
  }
}

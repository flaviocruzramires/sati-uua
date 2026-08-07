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
    Widget segment(SegmentedOption<T> opt) {
      final selected = opt.value == value;
      return GestureDetector(
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
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      );
    }

    // fullWidth: segmentos dividem a largura igualmente numa única linha.
    if (fullWidth) {
      return Row(
        children: options.map((o) => Expanded(child: segment(o))).toList(),
      );
    }

    // Padrão: quebra para a próxima linha quando não cabe — evita o overflow
    // horizontal (segmentos saindo da tela) em telas estreitas.
    return Wrap(
      spacing: 0,
      runSpacing: 0,
      children: options.map(segment).toList(),
    );
  }
}

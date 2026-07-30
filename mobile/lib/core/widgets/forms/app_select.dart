import 'package:flutter/material.dart';

import '../../domain/combo_item.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'field_label.dart';

export '../../domain/combo_item.dart';

class AppSelect<T> extends StatelessWidget {
  const AppSelect({
    super.key,
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.obrigatorio = false,
    this.loading = false,
    this.errorText,
  });

  final String label;
  final List<ComboItem<T>> items;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String? placeholder;
  final bool obrigatorio;
  final bool loading;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, obrigatorio: obrigatorio),
        const SizedBox(height: AppSpacing.s1),
        loading
            ? _LoadingInput()
            : DropdownButtonFormField<T>(
                value: value,
                isExpanded: true,
                decoration: InputDecoration(
                  errorText: errorText,
                ),
                hint: placeholder != null
                    ? Text(
                        placeholder!,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: AppColors.neutral500),
                      )
                    : null,
                items: items
                    .map((e) => DropdownMenuItem<T>(
                          value: e.id,
                          child: Text(e.label),
                        ))
                    .toList(),
                onChanged: onChanged,
                style: Theme.of(context).textTheme.bodyMedium,
                dropdownColor: AppColors.surface,
                borderRadius: BorderRadius.zero,
              ),
      ],
    );
  }
}

class _LoadingInput extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

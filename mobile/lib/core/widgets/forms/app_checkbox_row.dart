import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';

class AppCheckboxRow extends StatelessWidget {
  const AppCheckboxRow({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!value),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: Checkbox(
              value: value,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: AppColors.navy,
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
              side: const BorderSide(color: AppColors.neutral400),
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

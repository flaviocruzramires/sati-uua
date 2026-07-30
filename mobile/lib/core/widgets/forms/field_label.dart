import 'package:flutter/material.dart';

class FieldLabel extends StatelessWidget {
  const FieldLabel({super.key, required this.label, this.obrigatorio = false});

  final String label;
  final bool obrigatorio;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: style),
        if (obrigatorio) Text(' *', style: style?.copyWith(color: Colors.red)),
      ],
    );
  }
}

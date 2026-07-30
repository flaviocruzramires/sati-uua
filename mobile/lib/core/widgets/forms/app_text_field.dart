import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'field_label.dart';

class AppTextField extends StatelessWidget {
  const AppTextField({
    super.key,
    required this.label,
    required this.controller,
    this.obrigatorio = false,
    this.hint,
    this.obscure = false,
    this.errorText,
    this.validator,
    this.keyboardType,
    this.onChanged,
    this.enabled = true,
  });

  final String label;
  final TextEditingController controller;
  final bool obrigatorio;
  final String? hint;
  final bool obscure;
  final String? errorText;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, obrigatorio: obrigatorio),
        const SizedBox(height: AppSpacing.s1),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          enabled: enabled,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}

class AppTextArea extends StatelessWidget {
  const AppTextArea({
    super.key,
    required this.label,
    required this.controller,
    this.obrigatorio = false,
    this.hint,
    this.errorText,
    this.validator,
    this.maxLines = 4,
    this.onChanged,
  });

  final String label;
  final TextEditingController controller;
  final bool obrigatorio;
  final String? hint;
  final String? errorText;
  final String? Function(String?)? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, obrigatorio: obrigatorio),
        const SizedBox(height: AppSpacing.s1),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          onChanged: onChanged,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            errorText: errorText,
          ),
        ),
      ],
    );
  }
}


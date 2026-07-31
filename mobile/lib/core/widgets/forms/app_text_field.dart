import 'package:flutter/material.dart';

import '../../theme/app_spacing.dart';
import 'field_label.dart';

class AppTextField extends StatefulWidget {
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
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscure;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: widget.label, obrigatorio: widget.obrigatorio),
        const SizedBox(height: AppSpacing.s1),
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          enabled: widget.enabled,
          onChanged: widget.onChanged,
          validator: widget.validator,
          decoration: InputDecoration(
            hintText: widget.hint,
            errorText: widget.errorText,
            suffixIcon: widget.obscure
                ? IconButton(
                    icon: Icon(
                      _obscured ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                    ),
                    tooltip: _obscured ? 'Mostrar senha' : 'Ocultar senha',
                    onPressed: () => setState(() => _obscured = !_obscured),
                  )
                : null,
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
          decoration: InputDecoration(hintText: hint, errorText: errorText),
        ),
      ],
    );
  }
}

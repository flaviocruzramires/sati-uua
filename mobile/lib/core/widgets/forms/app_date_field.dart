import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import 'field_label.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');
final _dateTimeFmt = DateFormat('dd/MM/yyyy HH:mm');

class AppDateField extends StatelessWidget {
  const AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.obrigatorio = false,
    this.firstDate,
    this.lastDate,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool obrigatorio;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, obrigatorio: obrigatorio),
        const SizedBox(height: AppSpacing.s1),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(2000),
              lastDate: lastDate ?? DateTime(2100),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx),
                child: child!,
              ),
            );
            onChanged(picked);
          },
          child: _DateDisplayField(
            text: value != null ? _dateFmt.format(value!) : null,
            errorText: errorText,
            icon: LucideIcons.calendar,
          ),
        ),
      ],
    );
  }
}

class AppDateTimeField extends StatelessWidget {
  const AppDateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.obrigatorio = false,
    this.firstDate,
    this.lastDate,
    this.errorText,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool obrigatorio;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label: label, obrigatorio: obrigatorio),
        const SizedBox(height: AppSpacing.s1),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: value ?? DateTime.now(),
              firstDate: firstDate ?? DateTime(2000),
              lastDate: lastDate ?? DateTime(2100),
            );
            if (date == null || !context.mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime:
                  value != null ? TimeOfDay.fromDateTime(value!) : TimeOfDay.now(),
            );
            if (time == null) return;
            onChanged(DateTime(
                date.year, date.month, date.day, time.hour, time.minute));
          },
          child: _DateDisplayField(
            text: value != null ? _dateTimeFmt.format(value!) : null,
            errorText: errorText,
            icon: LucideIcons.calendarClock,
          ),
        ),
      ],
    );
  }
}

class _DateDisplayField extends StatelessWidget {
  const _DateDisplayField({this.text, this.errorText, required this.icon});

  final String? text;
  final String? errorText;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return InputDecorator(
      decoration: InputDecoration(
        errorText: errorText,
        suffixIcon: Icon(icon, size: 16, color: AppColors.neutral600),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(
            color: hasError ? Colors.red : AppColors.neutral300,
          ),
        ),
        focusedBorder: const OutlineInputBorder(
          borderRadius: BorderRadius.zero,
          borderSide: BorderSide(color: AppColors.navy, width: 2),
        ),
        filled: true,
        fillColor: AppColors.surface,
      ),
      child: Text(
        text ?? '',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: text == null ? AppColors.neutral500 : null,
            ),
      ),
    );
  }
}

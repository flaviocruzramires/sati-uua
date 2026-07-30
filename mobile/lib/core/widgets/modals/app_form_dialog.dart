import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../actions/app_button.dart';
import '../surfaces/section_divider.dart';

class AppFormDialog extends StatelessWidget {
  const AppFormDialog({
    super.key,
    required this.title,
    required this.fields,
    required this.onCancel,
    required this.onSave,
    this.saving = false,
  });

  final String title;
  final List<Widget> fields;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _DialogTitle(title: title, onCancel: onCancel),
            const SectionDivider(),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.s6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _intersperse(fields, const SizedBox(height: AppSpacing.s4)),
                ),
              ),
            ),
            const SectionDivider(),
            _DialogActions(onCancel: onCancel, onSave: onSave, saving: saving),
          ],
        ),
      ),
    );
  }

  static List<Widget> _intersperse(List<Widget> items, Widget separator) {
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) result.add(separator);
    }
    return result;
  }
}

class _DialogTitle extends StatelessWidget {
  const _DialogTitle({required this.title, required this.onCancel});
  final String title;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Text(title,
                style: Theme.of(context).textTheme.headlineSmall),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.zero),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogActions extends StatelessWidget {
  const _DialogActions(
      {required this.onCancel, required this.onSave, required this.saving});
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s6, vertical: AppSpacing.s4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          AppButton(
            label: 'Cancelar',
            onPressed: onCancel,
            variant: AppButtonVariant.secondary,
            centerLabel: true,
          ),
          const SizedBox(width: AppSpacing.s3),
          AppButton(
            label: 'Salvar',
            onPressed: onSave,
            loading: saving,
            centerLabel: true,
          ),
        ],
      ),
    );
  }
}

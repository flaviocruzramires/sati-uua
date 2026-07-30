import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/breakpoints.dart';
import '../actions/app_button.dart';
import '../surfaces/section_divider.dart';

/// Painel lateral (web: 360px fixo ao lado da lista) ou tela cheia (mobile).
/// Usado pelo Cadastro de Usuários (Modelo C, master-detail).
class AppSidePanelForm extends StatelessWidget {
  const AppSidePanelForm({
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
    if (Breakpoints.isMobile(context)) {
      return _FullScreenPanel(
        title: title,
        fields: fields,
        onCancel: onCancel,
        onSave: onSave,
        saving: saving,
      );
    }
    return _SidePanel(
      title: title,
      fields: fields,
      onCancel: onCancel,
      onSave: onSave,
      saving: saving,
    );
  }
}

class _SidePanel extends StatelessWidget {
  const _SidePanel({
    required this.title,
    required this.fields,
    required this.onCancel,
    required this.onSave,
    required this.saving,
  });

  final String title;
  final List<Widget> fields;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      color: AppColors.bg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelTitle(title: title, onCancel: onCancel),
          const SectionDivider(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _intersperse(
                  fields,
                  const SizedBox(height: AppSpacing.s4),
                ),
              ),
            ),
          ),
          const SectionDivider(),
          _PanelActions(onCancel: onCancel, onSave: onSave, saving: saving),
        ],
      ),
    );
  }
}

class _FullScreenPanel extends StatelessWidget {
  const _FullScreenPanel({
    required this.title,
    required this.fields,
    required this.onCancel,
    required this.onSave,
    required this.saving,
  });

  final String title;
  final List<Widget> fields;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.bg,
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: AppColors.bg),
        ),
        leading: IconButton(icon: const Icon(Icons.close), onPressed: onCancel),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _intersperse(
                  fields,
                  const SizedBox(height: AppSpacing.s4),
                ),
              ),
            ),
          ),
          const SectionDivider(),
          _PanelActions(onCancel: onCancel, onSave: onSave, saving: saving),
        ],
      ),
    );
  }
}

class _PanelTitle extends StatelessWidget {
  const _PanelTitle({required this.title, required this.onCancel});
  final String title;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s4,
        vertical: AppSpacing.s3,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: onCancel,
            style: IconButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelActions extends StatelessWidget {
  const _PanelActions({
    required this.onCancel,
    required this.onSave,
    required this.saving,
  });
  final VoidCallback onCancel;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              label: 'Cancelar',
              onPressed: onCancel,
              variant: AppButtonVariant.secondary,
              block: true,
              centerLabel: true,
            ),
          ),
          const SizedBox(width: AppSpacing.s3),
          Expanded(
            child: AppButton(
              label: 'Salvar',
              onPressed: onSave,
              loading: saving,
              block: true,
              centerLabel: true,
            ),
          ),
        ],
      ),
    );
  }
}

List<Widget> _intersperse(List<Widget> items, Widget separator) {
  final result = <Widget>[];
  for (var i = 0; i < items.length; i++) {
    result.add(items[i]);
    if (i < items.length - 1) result.add(separator);
  }
  return result;
}

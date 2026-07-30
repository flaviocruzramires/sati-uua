import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/paginated_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/actions/icon_action_button.dart';
import '../../../core/widgets/feedback/async_state_view.dart';
import '../../../core/widgets/forms/app_text_field.dart';
import '../../../core/widgets/forms/search_field.dart';
import '../../../core/widgets/listing/app_card_list_item.dart';
import '../../../core/widgets/listing/app_data_table.dart';
import '../../../core/widgets/listing/filter_bar.dart';
import '../../../core/widgets/listing/pagination_bar.dart';
import '../../../core/widgets/modals/app_form_dialog.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../tipo_equipamento_dto.dart';
import '../view_model/tipos_equipamento_view_model.dart';

class TiposEquipamentoView extends ConsumerWidget {
  const TiposEquipamentoView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final canWrite =
        user?.papel == PapelUsuario.admin ||
        user?.papel == PapelUsuario.atendente;

    final vmState = ref.watch(tiposEquipamentoViewModelProvider);
    final vm = ref.read(tiposEquipamentoViewModelProvider.notifier);

    void showForm([TipoEquipamentoDto? tipo]) {
      showDialog(
        context: context,
        builder: (_) => _TipoFormDialog(
          tipo: tipo,
          saving: vmState.saving,
          saveError: vmState.saveError,
          onSave: (nome) async {
            final ok = tipo == null
                ? await vm.create(nome)
                : await vm.update(tipo.id, nome);
            if (ok && context.mounted) Navigator.of(context).pop();
          },
          onCancel: () {
            vm.clearSaveError();
            Navigator.of(context).pop();
          },
        ),
      );
    }

    void confirmDelete(TipoEquipamentoDto t) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Excluir tipo'),
          content: Text('Deseja excluir "${t.nome}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final ok = await vm.delete(t.id);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        vmState.saveError ?? 'Erro ao excluir tipo',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              },
              child: const Text('Excluir', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
    }

    return AppShell(
      currentRoute: '/tipos-equipamento',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel ?? PapelUsuario.solicitante,
      title: 'Tipos de Equipamento',
      subtitle: 'Classificação de equipamentos',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      actions: canWrite
          ? [AppButton(label: '+ Novo Tipo', onPressed: () => showForm())]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterBar(
            search: SearchField(onChanged: vm.setBusca, hint: 'Buscar tipo...'),
            filters: const [],
            trailing: vmState.listState.whenOrNull(
              data: (r) => Text(
                '${r.total} tipo${r.total != 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ),
          Expanded(
            child: AsyncStateView<PaginatedResult<TipoEquipamentoDto>>(
              value: vmState.listState,
              onRetry: vm.load,
              empty: () => const Center(child: Text('Nenhum tipo encontrado')),
              builder: (result) => Breakpoints.isMobile(context)
                  ? _MobileList(
                      result: result,
                      canWrite: canWrite,
                      onEdit: showForm,
                      onDelete: confirmDelete,
                      onPageChange: vm.setPage,
                      currentPage: vmState.page,
                      pageSize: vmState.pageSize,
                    )
                  : _DesktopTable(
                      result: result,
                      canWrite: canWrite,
                      onEdit: showForm,
                      onDelete: confirmDelete,
                      onPageChange: vm.setPage,
                      currentPage: vmState.page,
                      pageSize: vmState.pageSize,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.result,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<TipoEquipamentoDto> result;
  final bool canWrite;
  final ValueChanged<TipoEquipamentoDto> onEdit;
  final ValueChanged<TipoEquipamentoDto> onDelete;
  final ValueChanged<int> onPageChange;
  final int currentPage;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: AppDataTable<TipoEquipamentoDto>(
              columns: const ['Nome'],
              rows: result.data,
              rowBuilder: (t) => [Text(t.nome)],
              actionsBuilder: canWrite
                  ? (t) => [
                      IconActionButton(
                        icon: LucideIcons.pencil,
                        tooltip: 'Editar',
                        onPressed: () => onEdit(t),
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      IconActionButton(
                        icon: LucideIcons.trash2,
                        tooltip: 'Excluir',
                        onPressed: () => onDelete(t),
                      ),
                    ]
                  : null,
            ),
          ),
        ),
        PaginationBar(
          total: result.total,
          page: currentPage,
          pageSize: pageSize,
          onPageChanged: onPageChange,
        ),
      ],
    );
  }
}

class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.result,
    required this.canWrite,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<TipoEquipamentoDto> result;
  final bool canWrite;
  final ValueChanged<TipoEquipamentoDto> onEdit;
  final ValueChanged<TipoEquipamentoDto> onDelete;
  final ValueChanged<int> onPageChange;
  final int currentPage;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.s3),
            itemCount: result.data.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
            itemBuilder: (_, i) {
              final t = result.data[i];
              return AppCardListItem(
                titulo: t.nome,
                tagSlot: canWrite
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconActionButton(
                            icon: LucideIcons.pencil,
                            tooltip: 'Editar',
                            onPressed: () => onEdit(t),
                          ),
                          const SizedBox(width: AppSpacing.s1),
                          IconActionButton(
                            icon: LucideIcons.trash2,
                            tooltip: 'Excluir',
                            onPressed: () => onDelete(t),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),
        ),
        PaginationBar(
          total: result.total,
          page: currentPage,
          pageSize: pageSize,
          onPageChanged: onPageChange,
        ),
      ],
    );
  }
}

class _TipoFormDialog extends StatefulWidget {
  const _TipoFormDialog({
    required this.onSave,
    required this.onCancel,
    required this.saving,
    this.tipo,
    this.saveError,
  });

  final TipoEquipamentoDto? tipo;
  final Future<void> Function(String nome) onSave;
  final VoidCallback onCancel;
  final bool saving;
  final String? saveError;

  @override
  State<_TipoFormDialog> createState() => _TipoFormDialogState();
}

class _TipoFormDialogState extends State<_TipoFormDialog> {
  late final TextEditingController _ctrl;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.tipo?.nome ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nome = _ctrl.text.trim();
    if (nome.isEmpty) {
      setState(() => _localError = 'Nome é obrigatório');
      return;
    }
    setState(() => _localError = null);
    widget.onSave(nome);
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.saveError ?? _localError;
    return AppFormDialog(
      title: widget.tipo != null ? 'Editar Tipo' : 'Novo Tipo de Equipamento',
      saving: widget.saving,
      onCancel: widget.onCancel,
      onSave: _submit,
      fields: [
        if (error != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            color: Colors.red.shade50,
            child: Text(
              error,
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        AppTextField(
          label: 'Nome',
          obrigatorio: true,
          controller: _ctrl,
          errorText: _localError != null && _ctrl.text.trim().isEmpty
              ? _localError
              : null,
        ),
      ],
    );
  }
}

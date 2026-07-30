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
import '../servico_dto.dart';
import '../view_model/servicos_view_model.dart';

class ServicosView extends ConsumerWidget {
  const ServicosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final canWrite =
        user?.papel == PapelUsuario.admin ||
        user?.papel == PapelUsuario.atendente;

    final vmState = ref.watch(servicosViewModelProvider);
    final vm = ref.read(servicosViewModelProvider.notifier);

    void showForm([ServicoDto? servico]) {
      showDialog(
        context: context,
        builder: (_) => _ServicoFormDialog(
          servico: servico,
          saving: vmState.saving,
          saveError: vmState.saveError,
          onSave: (descricao) async {
            final ok = servico == null
                ? await vm.create(descricao)
                : await vm.update(servico.id, descricao);
            if (ok && context.mounted) Navigator.of(context).pop();
          },
          onCancel: () {
            vm.clearSaveError();
            Navigator.of(context).pop();
          },
        ),
      );
    }

    void confirmDelete(ServicoDto s) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Excluir serviço'),
          content: Text('Deseja excluir "${s.descricao}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final ok = await vm.delete(s.id);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        vmState.saveError ?? 'Erro ao excluir serviço',
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
      currentRoute: '/servicos',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel ?? PapelUsuario.solicitante,
      title: 'Serviços',
      subtitle: 'Gestão de serviços de TI',
      onNavigate: (route) => context.go(route),
      onLogout: () {},
      actions: canWrite
          ? [AppButton(label: '+ Novo Serviço', onPressed: () => showForm())]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterBar(
            search: SearchField(
              onChanged: vm.setBusca,
              hint: 'Buscar serviço...',
            ),
            filters: const [],
            trailing: vmState.listState.whenOrNull(
              data: (r) => Text(
                '${r.total} serviço${r.total != 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ),
          Expanded(
            child: AsyncStateView<PaginatedResult<ServicoDto>>(
              value: vmState.listState,
              onRetry: vm.load,
              empty: () =>
                  const Center(child: Text('Nenhum serviço encontrado')),
              builder: (result) {
                if (Breakpoints.isMobile(context)) {
                  return _MobileList(
                    result: result,
                    canWrite: canWrite,
                    onEdit: showForm,
                    onDelete: confirmDelete,
                    onPageChange: vm.setPage,
                    currentPage: vmState.page,
                    pageSize: vmState.pageSize,
                  );
                }
                return _DesktopTable(
                  result: result,
                  canWrite: canWrite,
                  onEdit: showForm,
                  onDelete: confirmDelete,
                  onPageChange: vm.setPage,
                  currentPage: vmState.page,
                  pageSize: vmState.pageSize,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

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

  final PaginatedResult<ServicoDto> result;
  final bool canWrite;
  final ValueChanged<ServicoDto> onEdit;
  final ValueChanged<ServicoDto> onDelete;
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
            child: AppDataTable<ServicoDto>(
              columns: const ['Descrição'],
              rows: result.data,
              rowBuilder: (s) => [Text(s.descricao)],
              actionsBuilder: canWrite
                  ? (s) => [
                      IconActionButton(
                        icon: LucideIcons.pencil,
                        tooltip: 'Editar',
                        onPressed: () => onEdit(s),
                      ),
                      const SizedBox(width: AppSpacing.s1),
                      IconActionButton(
                        icon: LucideIcons.trash2,
                        tooltip: 'Excluir',
                        onPressed: () => onDelete(s),
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

// ── Mobile ────────────────────────────────────────────────────────────────────

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

  final PaginatedResult<ServicoDto> result;
  final bool canWrite;
  final ValueChanged<ServicoDto> onEdit;
  final ValueChanged<ServicoDto> onDelete;
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
              final s = result.data[i];
              return AppCardListItem(
                titulo: s.descricao,
                metaLines: const [],
                tagSlot: canWrite
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconActionButton(
                            icon: LucideIcons.pencil,
                            tooltip: 'Editar',
                            onPressed: () => onEdit(s),
                          ),
                          const SizedBox(width: AppSpacing.s1),
                          IconActionButton(
                            icon: LucideIcons.trash2,
                            tooltip: 'Excluir',
                            onPressed: () => onDelete(s),
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

// ── Form Dialog ───────────────────────────────────────────────────────────────

class _ServicoFormDialog extends StatefulWidget {
  const _ServicoFormDialog({
    required this.onSave,
    required this.onCancel,
    required this.saving,
    this.servico,
    this.saveError,
  });

  final ServicoDto? servico;
  final Future<void> Function(String descricao) onSave;
  final VoidCallback onCancel;
  final bool saving;
  final String? saveError;

  @override
  State<_ServicoFormDialog> createState() => _ServicoFormDialogState();
}

class _ServicoFormDialogState extends State<_ServicoFormDialog> {
  late final TextEditingController _ctrl;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.servico?.descricao ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final descricao = _ctrl.text.trim();
    if (descricao.isEmpty) {
      setState(() => _localError = 'Descrição é obrigatória');
      return;
    }
    setState(() => _localError = null);
    widget.onSave(descricao);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.servico != null;
    final error = widget.saveError ?? _localError;

    return AppFormDialog(
      title: isEdit ? 'Editar Serviço' : 'Novo Serviço',
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
          label: 'Descrição',
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

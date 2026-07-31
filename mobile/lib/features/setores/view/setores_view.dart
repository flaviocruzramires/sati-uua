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
import '../setor_dto.dart';
import '../view_model/setores_view_model.dart';

class SetoresView extends ConsumerWidget {
  const SetoresView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final user = userAsync.valueOrNull;
    final isAdmin = user?.papel == PapelUsuario.admin;

    final vmState = ref.watch(setoresViewModelProvider);
    final vm = ref.read(setoresViewModelProvider.notifier);

    void showForm([SetorDto? setor]) {
      showDialog(
        context: context,
        builder: (_) => _SetorFormDialog(
          setor: setor,
          saving: vmState.saving,
          saveError: vmState.saveError,
          onSave: (nome) async {
            final ok = setor == null
                ? await vm.create(nome)
                : await vm.update(setor.id, nome);
            if (ok && context.mounted) Navigator.of(context).pop();
          },
          onCancel: () {
            vm.clearSaveError();
            Navigator.of(context).pop();
          },
        ),
      );
    }

    void confirmDelete(SetorDto s) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Excluir setor'),
          content: Text('Deseja excluir "${s.nome}"?'),
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
                        vmState.saveError ?? 'Erro ao excluir setor',
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
      currentRoute: '/setores',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel,
      title: 'Setores',
      subtitle: 'Gestão de setores',
      onNavigate: (route) => context.go(route),
      onLogout: () {},
      actions: isAdmin
          ? [AppButton(label: '+ Novo Setor', onPressed: () => showForm())]
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterBar(
            search: SearchField(
              onChanged: vm.setBusca,
              hint: 'Buscar setor...',
            ),
            filters: const [],
            trailing: vmState.listState.whenOrNull(
              data: (r) => Text(
                '${r.total} setor${r.total != 1 ? 'es' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ),
          Expanded(
            child: AsyncStateView<PaginatedResult<SetorDto>>(
              value: vmState.listState,
              onRetry: vm.load,
              empty: () => const Center(child: Text('Nenhum setor encontrado')),
              builder: (result) {
                if (Breakpoints.isMobile(context)) {
                  return _MobileList(
                    result: result,
                    isAdmin: isAdmin,
                    onEdit: showForm,
                    onDelete: confirmDelete,
                    onPageChange: vm.setPage,
                    currentPage: vmState.page,
                    pageSize: vmState.pageSize,
                  );
                }
                return _DesktopTable(
                  result: result,
                  isAdmin: isAdmin,
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
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<SetorDto> result;
  final bool isAdmin;
  final ValueChanged<SetorDto> onEdit;
  final ValueChanged<SetorDto> onDelete;
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
            child: AppDataTable<SetorDto>(
              columns: const ['Nome'],
              rows: result.data,
              rowBuilder: (s) => [Text(s.nome)],
              actionsBuilder: isAdmin
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
    required this.isAdmin,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<SetorDto> result;
  final bool isAdmin;
  final ValueChanged<SetorDto> onEdit;
  final ValueChanged<SetorDto> onDelete;
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
                titulo: s.nome,
                metaLines: const [],
                tagSlot: isAdmin
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

class _SetorFormDialog extends StatefulWidget {
  const _SetorFormDialog({
    required this.onSave,
    required this.onCancel,
    required this.saving,
    this.setor,
    this.saveError,
  });

  final SetorDto? setor;
  final Future<void> Function(String nome) onSave;
  final VoidCallback onCancel;
  final bool saving;
  final String? saveError;

  @override
  State<_SetorFormDialog> createState() => _SetorFormDialogState();
}

class _SetorFormDialogState extends State<_SetorFormDialog> {
  late final TextEditingController _nomeCtrl;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _nomeCtrl = TextEditingController(text: widget.setor?.nome ?? '');
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nome = _nomeCtrl.text.trim();
    if (nome.isEmpty) {
      setState(() => _localError = 'Nome é obrigatório');
      return;
    }
    setState(() => _localError = null);
    widget.onSave(nome);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.setor != null;
    final error = widget.saveError ?? _localError;

    return AppFormDialog(
      title: isEdit ? 'Editar Setor' : 'Novo Setor',
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
          controller: _nomeCtrl,
          errorText: _localError != null && _nomeCtrl.text.trim().isEmpty
              ? _localError
              : null,
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/auth/permissoes_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/paginated_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/actions/icon_action_button.dart';
import '../../../core/widgets/feedback/async_state_view.dart';
import '../../../core/widgets/forms/app_checkbox_row.dart';
import '../../../core/widgets/forms/app_select.dart';
import '../../../core/widgets/forms/app_text_field.dart';
import '../../../core/widgets/listing/app_card_list_item.dart';
import '../../../core/widgets/listing/app_data_table.dart';
import '../../../core/widgets/listing/filter_bar.dart';
import '../../../core/widgets/listing/pagination_bar.dart';
import '../../../core/widgets/modals/app_form_dialog.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/tags/app_tag.dart';
import '../../../features/setores/setor_repository.dart';
import '../equipamento_dto.dart';
import '../equipamento_repository.dart';
import '../view_model/equipamentos_view_model.dart';

class EquipamentosView extends ConsumerWidget {
  const EquipamentosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final perm = ref.watch(permissoesHelperProvider);
    final podeIncluir = perm.podeIncluir('cadastros.equip');
    final podeAlterar = perm.podeAlterar('cadastros.equip');
    final podeExcluir = perm.podeExcluir('cadastros.equip');

    final vmState = ref.watch(equipamentosViewModelProvider);
    final vm = ref.read(equipamentosViewModelProvider.notifier);

    final tiposCombo = vmState.tiposCombo.valueOrNull ?? [];

    void showForm([EquipamentoDto? eq]) {
      showDialog(
        context: context,
        builder: (_) => _EquipamentoFormDialog(
          equipamento: eq,
          tiposCombo: tiposCombo,
          saving: vmState.saving,
          saveError: vmState.saveError,
          onSave:
              ({
                required String descricao,
                required int tipoId,
                int? setorId,
                required bool ativo,
              }) async {
                final bool ok;
                if (eq == null) {
                  ok = await vm.create(
                    descricao: descricao,
                    tipoEquipamentoId: tipoId,
                    setorId: setorId,
                  );
                } else {
                  ok = await vm.update(
                    id: eq.id,
                    descricao: descricao,
                    tipoEquipamentoId: tipoId,
                    setorId: setorId,
                    ativo: ativo,
                  );
                }
                if (ok && context.mounted) Navigator.of(context).pop();
              },
          onCancel: () {
            vm.clearSaveError();
            Navigator.of(context).pop();
          },
        ),
      );
    }

    void confirmDelete(EquipamentoDto eq) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          title: const Text('Excluir equipamento'),
          content: Text('Deseja excluir "${eq.descricao}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final ok = await vm.delete(eq.id);
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        vmState.saveError ?? 'Erro ao excluir equipamento',
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

    // Filtro por tipo como select na FilterBar
    final tipoFiltroItems = [
      const ComboItem<int?>(null, 'Todos os tipos'),
      ...tiposCombo.map((t) => ComboItem<int?>(t.id, t.label)),
    ];

    return AppShell(
      currentRoute: '/equipamentos',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel,
      title: 'Equipamentos',
      subtitle: 'Inventário de equipamentos',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      actions: [
        if (Breakpoints.isMobile(context)) ...[
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.neutral700),
            tooltip: 'Atualizar',
            onPressed: vm.load,
          ),
          if (podeIncluir)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.navy),
              tooltip: 'Novo Equipamento',
              onPressed: () => showForm(),
            ),
        ] else if (podeIncluir)
          AppButton(label: '+ Novo Equipamento', onPressed: () => showForm()),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterBar(
            filters: [
              SizedBox(
                width: 220,
                child: AppSelect<int?>(
                  label: 'Tipo',
                  value: vmState.filtroTipoId,
                  items: tipoFiltroItems,
                  onChanged: vm.setFiltroTipo,
                ),
              ),
            ],
            trailing: vmState.listState.whenOrNull(
              data: (r) => Text(
                '${r.total} equipamento${r.total != 1 ? 's' : ''}',
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
              ),
            ),
          ),
          Expanded(
            child: AsyncStateView<PaginatedResult<EquipamentoDto>>(
              value: vmState.listState,
              onRetry: vm.load,
              empty: () =>
                  const Center(child: Text('Nenhum equipamento encontrado')),
              builder: (result) => Breakpoints.isMobile(context)
                  ? _MobileList(
                      result: result,
                      podeAlterar: podeAlterar,
                      podeExcluir: podeExcluir,
                      onEdit: showForm,
                      onDelete: confirmDelete,
                      onPageChange: vm.setPage,
                      currentPage: vmState.page,
                      pageSize: vmState.pageSize,
                    )
                  : _DesktopTable(
                      result: result,
                      podeAlterar: podeAlterar,
                      podeExcluir: podeExcluir,
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

// ── Desktop ───────────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.result,
    required this.podeAlterar,
    required this.podeExcluir,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<EquipamentoDto> result;
  final bool podeAlterar;
  final bool podeExcluir;
  final ValueChanged<EquipamentoDto> onEdit;
  final ValueChanged<EquipamentoDto> onDelete;
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
            child: AppDataTable<EquipamentoDto>(
              columns: const ['Descrição', 'Tipo', 'Setor', 'Status'],
              rows: result.data,
              rowBuilder: (eq) => [
                Text(eq.descricao),
                Text(eq.tipoEquipamentoNome),
                Text(eq.setorNome ?? '—'),
                AtivoTag(
                  status: eq.ativo ? StatusAtivo.ativo : StatusAtivo.inativo,
                ),
              ],
              actionsBuilder: (podeAlterar || podeExcluir)
                  ? (eq) => [
                      if (podeAlterar)
                        IconActionButton(
                          icon: LucideIcons.pencil,
                          tooltip: 'Editar',
                          onPressed: () => onEdit(eq),
                        ),
                      if (podeAlterar && podeExcluir)
                        const SizedBox(width: AppSpacing.s1),
                      if (podeExcluir)
                        IconActionButton(
                          icon: LucideIcons.trash2,
                          tooltip: 'Excluir',
                          onPressed: () => onDelete(eq),
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
    required this.podeAlterar,
    required this.podeExcluir,
    required this.onEdit,
    required this.onDelete,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<EquipamentoDto> result;
  final bool podeAlterar;
  final bool podeExcluir;
  final ValueChanged<EquipamentoDto> onEdit;
  final ValueChanged<EquipamentoDto> onDelete;
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
              final eq = result.data[i];
              return AppCardListItem(
                titulo: eq.descricao,
                metaLines: [
                  eq.tipoEquipamentoNome,
                  if (eq.setorNome != null) eq.setorNome!,
                ],
                tagSlot: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AtivoTag(
                      status: eq.ativo
                          ? StatusAtivo.ativo
                          : StatusAtivo.inativo,
                    ),
                    if (podeAlterar) ...[
                      const SizedBox(width: AppSpacing.s1),
                      IconActionButton(
                        icon: LucideIcons.pencil,
                        tooltip: 'Editar',
                        onPressed: () => onEdit(eq),
                      ),
                    ],
                    if (podeExcluir) ...[
                      const SizedBox(width: AppSpacing.s1),
                      IconActionButton(
                        icon: LucideIcons.trash2,
                        tooltip: 'Excluir',
                        onPressed: () => onDelete(eq),
                      ),
                    ],
                  ],
                ),
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

class _EquipamentoFormDialog extends ConsumerStatefulWidget {
  const _EquipamentoFormDialog({
    required this.onSave,
    required this.onCancel,
    required this.saving,
    required this.tiposCombo,
    this.equipamento,
    this.saveError,
  });

  final EquipamentoDto? equipamento;
  final List<ComboItem<int>> tiposCombo;
  final Future<void> Function({
    required String descricao,
    required int tipoId,
    int? setorId,
    required bool ativo,
  })
  onSave;
  final VoidCallback onCancel;
  final bool saving;
  final String? saveError;

  @override
  ConsumerState<_EquipamentoFormDialog> createState() =>
      _EquipamentoFormDialogState();
}

class _EquipamentoFormDialogState
    extends ConsumerState<_EquipamentoFormDialog> {
  late final TextEditingController _descCtrl;
  int? _tipoId;
  int? _setorId;
  bool _ativo = true;
  String? _localError;

  // Combos de setor carregados ao abrir
  List<ComboItem<int?>> _setoresCombo = [
    const ComboItem<int?>(null, 'Sem setor'),
  ];
  bool _setoresLoading = true;

  @override
  void initState() {
    super.initState();
    final eq = widget.equipamento;
    _descCtrl = TextEditingController(text: eq?.descricao ?? '');
    _tipoId = eq?.tipoEquipamentoId;
    _setorId = eq?.setorId;
    _ativo = eq?.ativo ?? true;
    _loadSetores();
  }

  Future<void> _loadSetores() async {
    try {
      final repo = ref.read(setorRepositoryProvider);
      final result = await repo.list(pageSize: 200);
      if (mounted) {
        setState(() {
          _setoresCombo = [
            const ComboItem<int?>(null, 'Sem setor'),
            ...result.data.map((s) => ComboItem<int?>(s.id, s.nome)),
          ];
          _setoresLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _setoresLoading = false);
    }
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final descricao = _descCtrl.text.trim();
    if (descricao.isEmpty) {
      setState(() => _localError = 'Descrição é obrigatória');
      return;
    }
    if (_tipoId == null) {
      setState(() => _localError = 'Tipo é obrigatório');
      return;
    }
    setState(() => _localError = null);
    widget.onSave(
      descricao: descricao,
      tipoId: _tipoId!,
      setorId: _setorId,
      ativo: _ativo,
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.saveError ?? _localError;
    final tipoItems = widget.tiposCombo
        .map((t) => ComboItem<int>(t.id, t.label))
        .toList();

    return AppFormDialog(
      title: widget.equipamento != null
          ? 'Editar Equipamento'
          : 'Novo Equipamento',
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
          controller: _descCtrl,
        ),
        AppSelect<int>(
          label: 'Tipo de Equipamento',
          obrigatorio: true,
          value: _tipoId,
          items: tipoItems,
          onChanged: (v) => setState(() => _tipoId = v),
        ),
        AppSelect<int?>(
          label: 'Setor',
          value: _setorId,
          items: _setoresCombo,
          loading: _setoresLoading,
          onChanged: (v) => setState(() => _setorId = v),
        ),
        if (widget.equipamento != null)
          AppCheckboxRow(
            label: 'Ativo',
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v),
          ),
      ],
    );
  }
}

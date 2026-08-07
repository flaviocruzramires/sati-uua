import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/auth/permissoes_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/domain/paginated_result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/feedback/async_state_view.dart';
import '../../../core/widgets/forms/app_select.dart';
import '../../../core/widgets/listing/app_card_list_item.dart';
import '../../../core/widgets/listing/app_data_table.dart';
import '../../../core/widgets/listing/filter_bar.dart';
import '../../../core/widgets/listing/pagination_bar.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/tags/app_tag.dart';
import '../../usuarios/usuario_repository.dart';
import '../chamado_dto.dart';
import '../view_model/chamados_list_view_model.dart';

final _dateFmt = DateFormat('dd/MM/yyyy');

// Provider que carrega apenas atendentes para o filtro
final _atendentesProvider = FutureProvider<List<UsuarioDto>>((ref) async {
  final repo = ref.read(usuarioRepositoryProvider);
  final result = await repo.list(papel: PapelUsuario.atendente, pageSize: 200);
  return result.data;
});

class ChamadosListView extends ConsumerWidget {
  const ChamadosListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final podeAbrir =
        ref.watch(permissoesHelperProvider).podeIncluir('chamados.abertura');
    final vmState = ref.watch(chamadosListViewModelProvider);
    final vm = ref.read(chamadosListViewModelProvider.notifier);
    final atendentes = ref.watch(_atendentesProvider).valueOrNull ?? [];

    final situacaoItems = [
      const ComboItem<SituacaoChamado?>(null, 'Todos'),
      const ComboItem<SituacaoChamado?>(SituacaoChamado.aberto, 'Aberto'),
      const ComboItem<SituacaoChamado?>(
        SituacaoChamado.emAndamento,
        'Em andamento',
      ),
      const ComboItem<SituacaoChamado?>(
        SituacaoChamado.aguardandoSolicitante,
        'Aguard. solicitante',
      ),
      const ComboItem<SituacaoChamado?>(SituacaoChamado.encerrado, 'Encerrado'),
    ];

    final atendenteItems = [
      const ComboItem<int?>(null, 'Todos os atendentes'),
      ...atendentes.map((a) => ComboItem<int?>(a.id, a.nome)),
    ];

    final isMobile = Breakpoints.isMobile(context);

    return AppShell(
      currentRoute: '/chamados',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel,
      title: 'Chamados',
      subtitle: 'Fila de atendimento',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      actions: [
        if (isMobile) ...[
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.neutral700),
            tooltip: 'Atualizar',
            onPressed: vm.load,
          ),
          if (podeAbrir)
            IconButton(
              icon: const Icon(Icons.add, color: AppColors.navy),
              tooltip: 'Abrir Chamado',
              onPressed: () => context.go('/chamados/abrir'),
            ),
        ] else if (podeAbrir)
          AppButton(
            label: '+ Abrir Chamado',
            onPressed: () => context.go('/chamados/abrir'),
          ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isMobile)
            _MobileFilterBar(
              vmState: vmState,
              vm: vm,
              situacaoItems: situacaoItems,
            )
          else
            _DesktopFilterBar(
              vmState: vmState,
              vm: vm,
              situacaoItems: situacaoItems,
              atendenteItems: atendenteItems,
            ),
          Expanded(
            child: AsyncStateView<PaginatedResult<ChamadoDto>>(
              value: vmState.listState,
              onRetry: vm.load,
              empty: () =>
                  const Center(child: Text('Nenhum chamado para este filtro')),
              builder: (result) => isMobile
                  ? _MobileList(
                      result: result,
                      currentPage: vmState.page,
                      pageSize: vmState.pageSize,
                      onPageChange: vm.setPage,
                      onTap: (c) => context.go('/chamados/${c.id}'),
                    )
                  : _DesktopTable(
                      result: result,
                      currentPage: vmState.page,
                      pageSize: vmState.pageSize,
                      onPageChange: vm.setPage,
                      onTap: (c) => context.go('/chamados/${c.id}'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Desktop filter bar ────────────────────────────────────────────────────────

class _DesktopFilterBar extends StatelessWidget {
  const _DesktopFilterBar({
    required this.vmState,
    required this.vm,
    required this.situacaoItems,
    required this.atendenteItems,
  });

  final ChamadosListState vmState;
  final ChamadosListViewModel vm;
  final List<ComboItem<SituacaoChamado?>> situacaoItems;
  final List<ComboItem<int?>> atendenteItems;

  @override
  Widget build(BuildContext context) {
    final temFiltro = vmState.filtroSituacao != null ||
        vmState.filtroResponsavelId != null ||
        vmState.dataAberturaInicio != null ||
        vmState.dataAberturaFim != null;

    return FilterBar(
      filters: [
        SizedBox(
          width: 200,
          child: AppSelect<SituacaoChamado?>(
            label: 'Situação',
            value: vmState.filtroSituacao,
            items: situacaoItems,
            onChanged: vm.setFiltroSituacao,
          ),
        ),
        SizedBox(
          width: 200,
          child: AppSelect<int?>(
            label: 'Atendente',
            value: vmState.filtroResponsavelId,
            items: atendenteItems,
            onChanged: vm.setFiltroResponsavel,
          ),
        ),
        _DateFilterChip(
          label: 'De',
          value: vmState.dataAberturaInicio,
          onChanged: vm.setDataAberturaInicio,
        ),
        _DateFilterChip(
          label: 'Até',
          value: vmState.dataAberturaFim,
          onChanged: vm.setDataAberturaFim,
        ),
        if (temFiltro)
          TextButton(
            onPressed: vm.limparFiltros,
            child: const Text('Limpar'),
          ),
      ],
      trailing: vmState.listState.whenOrNull(
        data: (r) => Text(
          '${r.total} chamado${r.total != 1 ? 's' : ''}',
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}

// ── Mobile filter bar ─────────────────────────────────────────────────────────

class _MobileFilterBar extends StatelessWidget {
  const _MobileFilterBar({
    required this.vmState,
    required this.vm,
    required this.situacaoItems,
  });

  final ChamadosListState vmState;
  final ChamadosListViewModel vm;
  final List<ComboItem<SituacaoChamado?>> situacaoItems;

  @override
  Widget build(BuildContext context) {
    final temFiltro = vmState.filtroSituacao != null;
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        children: [
          ...situacaoItems.map((item) {
            final selected = vmState.filtroSituacao == item.id;
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s2),
              child: FilterChip(
                label: Text(item.label),
                selected: selected,
                onSelected: (_) => vm.setFiltroSituacao(item.id),
              ),
            );
          }),
          if (temFiltro)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s2),
              child: ActionChip(
                label: const Text('Limpar filtro'),
                avatar: const Icon(Icons.close, size: 14),
                onPressed: () => vm.setFiltroSituacao(null),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Date filter chip ──────────────────────────────────────────────────────────

class _DateFilterChip extends StatelessWidget {
  const _DateFilterChip({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2020),
          lastDate: DateTime.now().add(const Duration(days: 1)),
        );
        onChanged(picked);
      },
      borderRadius: BorderRadius.circular(4),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.neutral300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$label: ${value != null ? _dateFmt.format(value!) : '—'}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (value != null) ...[
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => onChanged(null),
                child: const Icon(Icons.close, size: 14, color: AppColors.muted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Desktop table ─────────────────────────────────────────────────────────────

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({
    required this.result,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChange,
    required this.onTap,
  });

  final PaginatedResult<ChamadoDto> result;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChange;
  final ValueChanged<ChamadoDto> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: AppDataTable<ChamadoDto>(
              columns: const [
                'Nº',
                'Descrição',
                'Solicitante',
                'Setor',
                'Situação',
                'Atendente',
                'Aberto em',
                'Último atendimento',
                'Retorno previsto',
              ],
              rows: result.data,
              onRowTap: onTap,
              rowBuilder: (c) => [
                Text('#${c.id}'),
                Text(
                  c.descricao.length > 55
                      ? '${c.descricao.substring(0, 55)}…'
                      : c.descricao,
                ),
                Text(c.solicitanteNome),
                Text(
                  c.solicitanteSetorNome ?? '—',
                  style: c.solicitanteSetorNome == null
                      ? const TextStyle(color: AppColors.muted)
                      : null,
                ),
                StatusChamadoTag(situacao: c.situacao),
                Text(
                  c.responsavelNome ?? '—',
                  style: c.responsavelNome == null
                      ? const TextStyle(color: AppColors.muted)
                      : null,
                ),
                Text(_formatDate(c.dataAbertura)),
                Text(
                  c.ultimoRetorno != null
                      ? _dateFmt.format(c.ultimoRetorno!.toLocal())
                      : '—',
                  style: c.ultimoRetorno == null
                      ? const TextStyle(color: AppColors.muted)
                      : null,
                ),
                Text(
                  c.dataPrevistaRetorno != null
                      ? _dateFmt.format(c.dataPrevistaRetorno!.toLocal())
                      : '—',
                  style: c.dataPrevistaRetorno == null
                      ? const TextStyle(color: AppColors.muted)
                      : null,
                ),
              ],
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

// ── Mobile list ───────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  const _MobileList({
    required this.result,
    required this.currentPage,
    required this.pageSize,
    required this.onPageChange,
    required this.onTap,
  });

  final PaginatedResult<ChamadoDto> result;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChange;
  final ValueChanged<ChamadoDto> onTap;

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
              final c = result.data[i];
              final subtitle = [
                c.solicitanteNome,
                if (c.solicitanteSetorNome != null) c.solicitanteSetorNome!,
                if (c.responsavelNome != null) c.responsavelNome!,
              ].join(' · ');
              final ultimoAtendimento = c.ultimoRetorno != null
                  ? 'Atendimento: ${_dateFmt.format(c.ultimoRetorno!.toLocal())}'
                  : null;
              final retornoPrevisto = c.dataPrevistaRetorno != null
                  ? 'Retorno previsto: ${_dateFmt.format(c.dataPrevistaRetorno!.toLocal())}'
                  : null;
              return AppCardListItem(
                titulo:
                    '#${c.id} · ${c.descricao.length > 50 ? '${c.descricao.substring(0, 50)}…' : c.descricao}',
                metaLines: [
                  subtitle,
                  _formatDate(c.dataAbertura),
                  if (ultimoAtendimento != null) ultimoAtendimento,
                  if (retornoPrevisto != null) retornoPrevisto,
                ],
                tagSlot: StatusChamadoTag(situacao: c.situacao),
                onTap: () => onTap(c),
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

String _formatDate(DateTime dt) =>
    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';

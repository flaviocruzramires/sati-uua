import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/current_user_provider.dart';
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
import '../chamado_dto.dart';
import '../view_model/chamados_list_view_model.dart';

class ChamadosListView extends ConsumerWidget {
  const ChamadosListView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final vmState = ref.watch(chamadosListViewModelProvider);
    final vm = ref.read(chamadosListViewModelProvider.notifier);

    final situacaoItems = [
      const ComboItem<SituacaoChamado?>(null, 'Todos'),
      const ComboItem<SituacaoChamado?>(SituacaoChamado.aberto, 'Aberto'),
      const ComboItem<SituacaoChamado?>(SituacaoChamado.emAndamento, 'Em andamento'),
      const ComboItem<SituacaoChamado?>(
          SituacaoChamado.aguardandoSolicitante, 'Aguard. solicitante'),
      const ComboItem<SituacaoChamado?>(SituacaoChamado.encerrado, 'Encerrado'),
    ];

    return AppShell(
      currentRoute: '/chamados',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel ?? PapelUsuario.solicitante,
      title: 'Chamados',
      subtitle: 'Fila de atendimento',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      actions: [
        AppButton(
          label: '+ Abrir Chamado',
          onPressed: () => context.go('/chamados/abrir'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FilterBar(
            filters: [
              SizedBox(
                width: 220,
                child: AppSelect<SituacaoChamado?>(
                  label: 'Situação',
                  value: vmState.filtroSituacao,
                  items: situacaoItems,
                  onChanged: vm.setFiltroSituacao,
                ),
              ),
            ],
            trailing: vmState.listState.whenOrNull(
              data: (r) => Text(
                '${r.total} chamado${r.total != 1 ? 's' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ),
          ),
          Expanded(
            child: AsyncStateView<PaginatedResult<ChamadoDto>>(
              value: vmState.listState,
              onRetry: vm.load,
              empty: () =>
                  const Center(child: Text('Nenhum chamado para este filtro')),
              builder: (result) => Breakpoints.isMobile(context)
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
                'Situação',
                'Atendente',
                'Aberto em',
              ],
              rows: result.data,
              onRowTap: onTap,
              rowBuilder: (c) => [
                Text('#${c.id}'),
                Text(
                  c.descricao.length > 60
                      ? '${c.descricao.substring(0, 60)}…'
                      : c.descricao,
                ),
                Text(c.solicitanteNome),
                StatusChamadoTag(situacao: c.situacao),
                Text(
                  c.responsavelNome ?? '—',
                  style: c.responsavelNome == null
                      ? TextStyle(color: AppColors.muted)
                      : null,
                ),
                Text(_formatDate(c.dataAbertura)),
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
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.s2),
            itemBuilder: (_, i) {
              final c = result.data[i];
              return AppCardListItem(
                titulo: '#${c.id} · ${c.descricao.length > 50 ? '${c.descricao.substring(0, 50)}…' : c.descricao}',
                metaLines: [
                  c.solicitanteNome,
                  if (c.responsavelNome != null)
                    'Atendente: ${c.responsavelNome}',
                  _formatDate(c.dataAbertura),
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

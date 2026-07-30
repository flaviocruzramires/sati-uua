import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/feedback/async_state_view.dart';
import '../../../core/widgets/forms/app_date_field.dart';
import '../../../core/widgets/forms/app_select.dart';
import '../../../core/widgets/listing/app_card_list_item.dart';
import '../../../core/widgets/listing/app_data_table.dart';
import '../../../core/widgets/listing/filter_bar.dart';
import '../../../core/widgets/listing/pagination_bar.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/tags/app_tag.dart';
import '../relatorio_dto.dart';
import '../view_model/relatorio_view_model.dart';

final _dtFmt = DateFormat('dd/MM/yyyy');

class RelatorioView extends ConsumerWidget {
  const RelatorioView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final vmState = ref.watch(relatorioViewModelProvider);
    final vm = ref.read(relatorioViewModelProvider.notifier);

    return AppShell(
      currentRoute: '/relatorios',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel ?? PapelUsuario.solicitante,
      title: 'Relatórios',
      subtitle: 'Chamados de TI',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FiltrosBar(
            filtros: vmState.filtros,
            onAplicar: vm.aplicarFiltros,
            onLimpar: vm.limparFiltros,
            trailing: vmState.resultState.whenOrNull(
              data: (r) => Text(
                '${r.resumo.total} resultado${r.resumo.total != 1 ? 's' : ''}',
                style: Theme.of(context)
                    .textTheme
                    .labelMedium
                    ?.copyWith(color: AppColors.muted),
              ),
            ),
          ),
          // Cabeçalho de resumo
          if (vmState.resultState.valueOrNull != null)
            _ResumoBar(resumo: vmState.resultState.valueOrNull!.resumo),
          Expanded(
            child: AsyncStateView<RelatorioResultDto>(
              value: vmState.resultState,
              onRetry: vm.buscar,
              empty: () => const Center(
                  child: Text('Nenhum chamado encontrado para os filtros')),
              builder: (result) => Breakpoints.isMobile(context)
                  ? _MobileList(
                      result: result,
                      currentPage: vmState.page,
                      pageSize: vmState.pageSize,
                      onPageChange: vm.setPage,
                      onTap: (item) =>
                          context.go('/chamados/${item.id}'),
                    )
                  : _DesktopTable(
                      result: result,
                      currentPage: vmState.page,
                      pageSize: vmState.pageSize,
                      onPageChange: vm.setPage,
                      onTap: (item) =>
                          context.go('/chamados/${item.id}'),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de filtros ──────────────────────────────────────────────────────────

class _FiltrosBar extends StatefulWidget {
  const _FiltrosBar({
    required this.filtros,
    required this.onAplicar,
    required this.onLimpar,
    this.trailing,
  });
  final RelatorioFiltros filtros;
  final ValueChanged<RelatorioFiltros> onAplicar;
  final VoidCallback onLimpar;
  final Widget? trailing;

  @override
  State<_FiltrosBar> createState() => _FiltrosBarState();
}

class _FiltrosBarState extends State<_FiltrosBar> {
  late SituacaoChamado? _situacao;
  late DateTime? _aberturaDe;
  late DateTime? _aberturaAte;

  @override
  void initState() {
    super.initState();
    _situacao = widget.filtros.situacao;
    _aberturaDe = widget.filtros.aberturaDe;
    _aberturaAte = widget.filtros.aberturaAte;
  }

  void _aplicar() {
    widget.onAplicar(RelatorioFiltros(
      situacao: _situacao,
      aberturaDe: _aberturaDe,
      aberturaAte: _aberturaAte,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final situacaoItems = [
      const ComboItem<SituacaoChamado?>(null, 'Todas as situações'),
      const ComboItem<SituacaoChamado?>(SituacaoChamado.aberto, 'Aberto'),
      const ComboItem<SituacaoChamado?>(
          SituacaoChamado.emAndamento, 'Em andamento'),
      const ComboItem<SituacaoChamado?>(
          SituacaoChamado.aguardandoSolicitante, 'Aguard. solicitante'),
      const ComboItem<SituacaoChamado?>(
          SituacaoChamado.encerrado, 'Encerrado'),
    ];

    return FilterBar(
      filters: [
        SizedBox(
          width: 200,
          child: AppSelect<SituacaoChamado?>(
            label: 'Situação',
            value: _situacao,
            items: situacaoItems,
            onChanged: (v) => setState(() => _situacao = v),
          ),
        ),
        SizedBox(
          width: 160,
          child: AppDateField(
            label: 'Abertura de',
            value: _aberturaDe,
            onChanged: (v) => setState(() => _aberturaDe = v),
          ),
        ),
        SizedBox(
          width: 160,
          child: AppDateField(
            label: 'Abertura até',
            value: _aberturaAte,
            onChanged: (v) => setState(() => _aberturaAte = v),
          ),
        ),
        AppButton(
          label: 'Buscar',
          onPressed: _aplicar,
        ),
        if (widget.filtros.hasAnyFilter)
          AppButton(
            label: 'Limpar',
            variant: AppButtonVariant.ghost,
            onPressed: () {
              setState(() {
                _situacao = null;
                _aberturaDe = null;
                _aberturaAte = null;
              });
              widget.onLimpar();
            },
          ),
      ],
      trailing: widget.trailing,
    );
  }
}

// ── Resumo ────────────────────────────────────────────────────────────────────

class _ResumoBar extends StatelessWidget {
  const _ResumoBar({required this.resumo});
  final RelatorioResumoDto resumo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
      color: AppColors.surface,
      child: Wrap(
        spacing: AppSpacing.s4,
        children: [
          _ResumoChip('Abertos', resumo.abertos, AppColors.navy),
          _ResumoChip(
              'Em andamento', resumo.emAndamento, AppColors.accent500),
          _ResumoChip('Aguardando', resumo.aguardandoSolicitante,
              AppColors.neutral600),
          _ResumoChip('Encerrados', resumo.encerrados, AppColors.neutral600),
          Text(
            'Tempo médio: ${resumo.tempoMedioFormatado}',
            style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
          ),
        ],
      ),
    );
  }
}

class _ResumoChip extends StatelessWidget {
  const _ResumoChip(this.label, this.valor, this.color);
  final String label;
  final int valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: $valor',
      style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w600, color: color),
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
  final RelatorioResultDto result;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChange;
  final ValueChanged<RelatorioItemDto> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            child: AppDataTable<RelatorioItemDto>(
              columns: const [
                'Nº',
                'Situação',
                'Solicitante',
                'Setor',
                'Atendente',
                'Serviço',
                'Aberto em',
                'Encerrado em',
              ],
              rows: result.data,
              onRowTap: onTap,
              rowBuilder: (item) => [
                Text('#${item.id}'),
                StatusChamadoTag(situacao: item.situacao),
                Text(item.solicitanteNome),
                Text(item.solicitanteSetor),
                Text(item.responsavelNome ?? '—',
                    style: item.responsavelNome == null
                        ? TextStyle(color: AppColors.muted)
                        : null),
                Text(item.servicoDescricao ?? '—',
                    style: item.servicoDescricao == null
                        ? TextStyle(color: AppColors.muted)
                        : null),
                Text(_dtFmt.format(item.dataAbertura.toLocal())),
                Text(item.dataFechamento != null
                    ? _dtFmt.format(item.dataFechamento!.toLocal())
                    : '—'),
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
  final RelatorioResultDto result;
  final int currentPage;
  final int pageSize;
  final ValueChanged<int> onPageChange;
  final ValueChanged<RelatorioItemDto> onTap;

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
              final item = result.data[i];
              return AppCardListItem(
                titulo: '#${item.id} · ${item.solicitanteNome}',
                metaLines: [
                  item.solicitanteSetor,
                  if (item.responsavelNome != null)
                    'Atendente: ${item.responsavelNome}',
                  _dtFmt.format(item.dataAbertura.toLocal()),
                ],
                tagSlot: StatusChamadoTag(situacao: item.situacao),
                onTap: () => onTap(item),
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

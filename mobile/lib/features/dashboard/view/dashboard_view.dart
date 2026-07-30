import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../dashboard_dto.dart';
import '../view_model/dashboard_view_model.dart';

class DashboardView extends ConsumerWidget {
  const DashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final vmState = ref.watch(dashboardViewModelProvider);
    final vm = ref.read(dashboardViewModelProvider.notifier);

    return AppShell(
      currentRoute: '/',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel ?? PapelUsuario.solicitante,
      title: 'Dashboard',
      subtitle: 'Visão geral dos chamados de TI',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      actions: [
        _PeriodoSegmented(
          dias: vmState.dias,
          onChanged: vm.setPeriodo,
        ),
      ],
      child: vmState.resumoState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erro ao carregar dashboard',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.s3),
              AppButton(label: 'Tentar novamente', onPressed: vm.load),
            ],
          ),
        ),
        data: (d) => Breakpoints.isMobile(context)
            ? _MobileContent(data: d)
            : _DesktopContent(data: d),
      ),
    );
  }
}

// ── Segmented de período ──────────────────────────────────────────────────────

class _PeriodoSegmented extends StatelessWidget {
  const _PeriodoSegmented({required this.dias, required this.onChanged});

  final int dias;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<int>(
      segments: const [
        ButtonSegment(value: 7, label: Text('7d')),
        ButtonSegment(value: 30, label: Text('30d')),
        ButtonSegment(value: 90, label: Text('90d')),
      ],
      selected: {dias},
      onSelectionChanged: (s) => onChanged(s.first),
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ),
    );
  }
}

// ── Desktop ───────────────────────────────────────────────────────────────────

class _DesktopContent extends StatelessWidget {
  const _DesktopContent({required this.data});
  final DashboardDto data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiRow(kpi: data.kpi),
          const SizedBox(height: AppSpacing.s6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _BarSection(
                  title: 'Chamados por Situação',
                  items: data.porSituacao,
                  color: AppColors.navy,
                  labelMapper: _situacaoLabel,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                flex: 4,
                child: _EvolucaoCard(items: data.evolucaoMensal),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BarSection(
                  title: 'Por Setor',
                  items: data.porSetor,
                  color: AppColors.navy,
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: _BarSection(
                  title: 'Por Tipo de Equipamento',
                  items: data.porTipoEquipamento,
                  color: const Color(0xFF2E7D32),
                ),
              ),
              const SizedBox(width: AppSpacing.s4),
              Expanded(
                child: _BarSection(
                  title: 'Por Serviço',
                  items: data.porServico,
                  color: AppColors.neutral600,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          _AtendenteTable(atendentes: data.porAtendente),
        ],
      ),
    );
  }
}

// ── Mobile ────────────────────────────────────────────────────────────────────

class _MobileContent extends StatelessWidget {
  const _MobileContent({required this.data});
  final DashboardDto data;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _KpiGrid(kpi: data.kpi),
          const SizedBox(height: AppSpacing.s3),
          _BarSection(
            title: 'Por Situação',
            items: data.porSituacao.take(4).toList(),
            color: AppColors.navy,
            labelMapper: _situacaoLabel,
          ),
          const SizedBox(height: AppSpacing.s3),
          _BarSection(
            title: 'Por Tipo de Equipamento',
            items: data.porTipoEquipamento.take(4).toList(),
            color: const Color(0xFF2E7D32),
          ),
          const SizedBox(height: AppSpacing.s3),
          _AtendenteList(atendentes: data.porAtendente.take(5).toList()),
        ],
      ),
    );
  }
}

// ── KPI ───────────────────────────────────────────────────────────────────────

class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpi});
  final KpiResumoDto kpi;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _KpiCard(kicker: 'ABERTOS', valor: '${kpi.abertos}',
            meta: '+hoje'),
        const SizedBox(width: AppSpacing.s3),
        _KpiCard(kicker: 'EM ANDAMENTO', valor: '${kpi.emAndamento}',
            meta: '${kpi.semAtendente} sem atendente'),
        const SizedBox(width: AppSpacing.s3),
        _KpiCard(kicker: 'AGUARDANDO', valor: '${kpi.aguardandoSolicitante}',
            meta: 'retorno pendente'),
        const SizedBox(width: AppSpacing.s3),
        _KpiCard(kicker: 'ENCERRADOS', valor: '${kpi.encerrados}',
            meta: 'no período'),
        const SizedBox(width: AppSpacing.s3),
        _KpiCard(kicker: 'TEMPO MÉDIO', valor: kpi.tempoMedioFormatado,
            meta: 'meta: 8h'),
      ].map((w) => Expanded(child: w)).toList(),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpi});
  final KpiResumoDto kpi;

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      childAspectRatio: 2.2,
      mainAxisSpacing: AppSpacing.s2,
      crossAxisSpacing: AppSpacing.s2,
      children: [
        _KpiCard(kicker: 'ABERTOS', valor: '${kpi.abertos}', meta: ''),
        _KpiCard(kicker: 'EM ANDAMENTO', valor: '${kpi.emAndamento}', meta: ''),
        _KpiCard(kicker: 'ENCERRADOS', valor: '${kpi.encerrados}', meta: ''),
        _KpiCard(kicker: 'TEMPO MÉDIO', valor: kpi.tempoMedioFormatado, meta: 'meta: 8h'),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard(
      {required this.kicker, required this.valor, required this.meta});
  final String kicker;
  final String valor;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(kicker,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AppColors.neutral600)),
            const SizedBox(height: AppSpacing.s1),
            Text(valor,
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w800)),
            if (meta.isNotEmpty)
              Text(meta,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.neutral600)),
          ],
        ),
      ),
    );
  }
}

// ── Barras horizontais ────────────────────────────────────────────────────────

class _BarSection extends StatelessWidget {
  const _BarSection({
    required this.title,
    required this.items,
    required this.color,
    this.labelMapper,
  });
  final String title;
  final List<BarItemDto> items;
  final Color color;
  final String Function(String)? labelMapper;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.s3),
              Text('Sem dados no período',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      );
    }

    final maxTotal =
        items.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s3),
            ...items.map((item) => _BarRow(
                  label: labelMapper?.call(item.label) ?? item.label,
                  total: item.total,
                  maxTotal: maxTotal,
                  color: color,
                )),
          ],
        ),
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({
    required this.label,
    required this.total,
    required this.maxTotal,
    required this.color,
  });
  final String label;
  final int total;
  final int maxTotal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final fraction = maxTotal > 0 ? total / maxTotal : 0.0;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(label,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis),
              ),
              Text('$total',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 2),
          LayoutBuilder(builder: (_, constraints) {
            return Stack(
              children: [
                Container(
                  height: 8,
                  width: constraints.maxWidth,
                  color: AppColors.neutral200,
                ),
                Container(
                  height: 8,
                  width: constraints.maxWidth * fraction,
                  color: color,
                ),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Evolução mensal ───────────────────────────────────────────────────────────

class _EvolucaoCard extends StatelessWidget {
  const _EvolucaoCard({required this.items});
  final List<MesItemDto> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text('Abertos × Encerrados',
              style: Theme.of(context).textTheme.titleMedium),
        ),
      );
    }

    final maxVal = items
        .expand((m) => [m.abertos, m.encerrados])
        .reduce((a, b) => a > b ? a : b);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Abertos × Encerrados — últimos 6 meses',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s2),
            Row(
              children: [
                _LegendaDot(color: AppColors.navy, label: 'Abertos'),
                const SizedBox(width: AppSpacing.s3),
                _LegendaDot(color: const Color(0xFF2E7D32), label: 'Encerrados'),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: items.map((m) {
                  final mesLabel = m.mes.substring(5); // MM
                  return Expanded(
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _MiniBar(
                                fraction:
                                    maxVal > 0 ? m.abertos / maxVal : 0,
                                color: AppColors.navy,
                              ),
                              const SizedBox(width: 2),
                              _MiniBar(
                                fraction: maxVal > 0
                                    ? m.encerrados / maxVal
                                    : 0,
                                color: const Color(0xFF2E7D32),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(mesLabel,
                              style: const TextStyle(
                                  fontSize: 10, color: AppColors.neutral600)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  const _MiniBar({required this.fraction, required this.color});
  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 12,
      height: 100 * fraction,
      color: color,
    );
  }
}

class _LegendaDot extends StatelessWidget {
  const _LegendaDot({required this.color, required this.label});
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, color: color),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

// ── Tabela por atendente (desktop) ────────────────────────────────────────────

class _AtendenteTable extends StatelessWidget {
  const _AtendenteTable({required this.atendentes});
  final List<AtendenteResumoDto> atendentes;

  @override
  Widget build(BuildContext context) {
    if (atendentes.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Por Atendente',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s3),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(3),
                1: FlexColumnWidth(2),
                2: FlexColumnWidth(1),
                3: FlexColumnWidth(1),
                4: FlexColumnWidth(2),
              },
              children: [
                TableRow(
                  decoration:
                      const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.divider))),
                  children: ['Atendente', 'Setor', 'Ativos', 'Encerrados', 'Tempo médio']
                      .map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.s2),
                            child: Text(h,
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.neutral600)),
                          ))
                      .toList(),
                ),
                ...atendentes.map((a) => TableRow(
                      children: [
                        _Cell(a.nome),
                        _Cell(a.setorNome),
                        _Cell('${a.ativos}'),
                        _Cell('${a.encerrados}'),
                        _Cell(_formatMinutos(a.tempoMedioMinutos)),
                      ],
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
        child: Text(text, style: const TextStyle(fontSize: 13)),
      );
}

// ── Lista de atendentes (mobile) ──────────────────────────────────────────────

class _AtendenteList extends StatelessWidget {
  const _AtendenteList({required this.atendentes});
  final List<AtendenteResumoDto> atendentes;

  @override
  Widget build(BuildContext context) {
    if (atendentes.isEmpty) return const SizedBox.shrink();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Por Atendente',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s2),
            ...atendentes.map(
              (a) => Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: AppSpacing.s1),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(a.nome,
                          style: const TextStyle(fontSize: 13)),
                    ),
                    Text(
                      '${a.ativos} ativos · ${a.encerrados} enc.',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.neutral600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _situacaoLabel(String raw) => switch (raw) {
      'ABERTO' => 'Aberto',
      'EM_ANDAMENTO' => 'Em andamento',
      'AGUARDANDO_SOLICITANTE' => 'Aguard. solicitante',
      'ENCERRADO' => 'Encerrado',
      _ => raw,
    };

String _formatMinutos(double min) {
  if (min <= 0) return '—';
  final h = (min / 60).floor();
  final m = (min % 60).round();
  if (h == 0) return '${m}min';
  return '${h}h${m.toString().padLeft(2, '0')}';
}

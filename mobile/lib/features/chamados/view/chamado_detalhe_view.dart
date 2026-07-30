import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/forms/app_checkbox_row.dart';
import '../../../core/widgets/forms/app_date_field.dart';
import '../../../core/widgets/forms/app_text_field.dart' show AppTextArea;
import '../../../core/widgets/tags/app_tag.dart';
import '../chamado_detalhe_dto.dart';
import '../chamado_dto.dart';
import '../view_model/chamado_detalhe_view_model.dart';

final _dtFmt = DateFormat('dd/MM/yyyy HH:mm');

class ChamadoDetalheView extends ConsumerWidget {
  const ChamadoDetalheView({super.key, required this.chamadoId});

  final int chamadoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmState = ref.watch(chamadoDetalheViewModelProvider(chamadoId));
    final vm = ref.read(chamadoDetalheViewModelProvider(chamadoId).notifier);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isAtendente = user?.papel == PapelUsuario.atendente ||
        user?.papel == PapelUsuario.admin;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/chamados'),
        ),
        title: vmState.detalheState.whenOrNull(
              data: (d) => Row(
                children: [
                  Text('Chamado #${d.chamado.id}'),
                  const SizedBox(width: AppSpacing.s2),
                  StatusChamadoTag(situacao: d.chamado.situacao),
                ],
              ),
            ) ??
            const Text('Chamado'),
      ),
      body: vmState.detalheState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erro ao carregar chamado',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.s3),
              AppButton(
                label: 'Tentar novamente',
                onPressed: () => vm.load(chamadoId),
              ),
            ],
          ),
        ),
        data: (detalhe) => _DetalheBody(
          detalhe: detalhe,
          chamadoId: chamadoId,
          isAtendente: isAtendente,
          userId: user?.id,
          vm: vm,
          vmState: vmState,
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _DetalheBody extends StatelessWidget {
  const _DetalheBody({
    required this.detalhe,
    required this.chamadoId,
    required this.isAtendente,
    required this.userId,
    required this.vm,
    required this.vmState,
  });

  final ChamadoDetalheDto detalhe;
  final int chamadoId;
  final bool isAtendente;
  final int? userId;
  final ChamadoDetalheViewModel vm;
  final ChamadoDetalheState vmState;

  @override
  Widget build(BuildContext context) {
    final chamado = detalhe.chamado;
    final encerrado = chamado.situacao == SituacaoChamado.encerrado;
    final semResponsavel = chamado.responsavelId == null;

    final resumoCard = _ResumoCard(chamado: chamado);
    final timeline = _Timeline(historico: detalhe.historico);
    final form = (!encerrado && isAtendente)
        ? _RegistroForm(
            chamadoId: chamadoId,
            vm: vm,
            vmState: vmState,
            semResponsavel: semResponsavel,
            userId: userId,
          )
        : null;

    if (Breakpoints.isMobile(context)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            resumoCard,
            const SizedBox(height: AppSpacing.s3),
            timeline,
            if (form != null) ...[
              const SizedBox(height: AppSpacing.s3),
              form,
            ],
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          resumoCard,
          const SizedBox(height: AppSpacing.s4),
          if (form != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 13, child: timeline),
                const SizedBox(width: AppSpacing.s4),
                Expanded(flex: 10, child: form),
              ],
            )
          else
            timeline,
        ],
      ),
    );
  }
}

// ── Resumo ────────────────────────────────────────────────────────────────────

class _ResumoCard extends StatelessWidget {
  const _ResumoCard({required this.chamado});

  final ChamadoDto chamado;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Solicitante', chamado.solicitanteNome),
      ('Equipamento', chamado.equipamentoDescricao ?? '—'),
      ('Serviço', chamado.servicoNome ?? '—'),
      ('Atendente', chamado.responsavelNome ?? '—'),
      ('Aberto em', _dtFmt.format(chamado.dataAbertura.toLocal())),
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.s4,
              runSpacing: AppSpacing.s3,
              children: items
                  .map((item) => _KickerValue(kicker: item.$1, value: item.$2))
                  .toList(),
            ),
            const Divider(height: AppSpacing.s6),
            Text('Descrição',
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: AppColors.muted)),
            const SizedBox(height: AppSpacing.s1),
            Text(chamado.descricao),
          ],
        ),
      ),
    );
  }
}

class _KickerValue extends StatelessWidget {
  const _KickerValue({required this.kicker, required this.value});

  final String kicker;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(kicker,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: AppColors.muted)),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.historico});

  final List<ChamadoHistoricoDto> historico;

  @override
  Widget build(BuildContext context) {
    if (historico.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Text(
            'Nenhum registro de atendimento ainda.',
            style: TextStyle(color: AppColors.muted),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Histórico de atendimento',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s3),
            ...List.generate(historico.length, (i) {
              final h = historico[i];
              final isLast = i == historico.length - 1;
              return _TimelineItem(item: h, isLast: isLast);
            }),
          ],
        ),
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({required this.item, required this.isLast});

  final ChamadoHistoricoDto item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  color: item.marcaEncerramento
                      ? AppColors.accent500
                      : AppColors.accent300,
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: AppColors.divider,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s2),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                  bottom: isLast ? 0 : AppSpacing.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.responsavelNome} · ${_dtFmt.format(item.dataRetorno.toLocal())}',
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: AppColors.muted),
                  ),
                  const SizedBox(height: AppSpacing.s1),
                  Text(item.descricao),
                  if (item.marcaEncerramento) ...[
                    const SizedBox(height: AppSpacing.s1),
                    Text('Chamado encerrado',
                        style: TextStyle(
                            color: AppColors.accent500,
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Formulário de registro ────────────────────────────────────────────────────

class _RegistroForm extends StatefulWidget {
  const _RegistroForm({
    required this.chamadoId,
    required this.vm,
    required this.vmState,
    required this.semResponsavel,
    required this.userId,
  });

  final int chamadoId;
  final ChamadoDetalheViewModel vm;
  final ChamadoDetalheState vmState;
  final bool semResponsavel;
  final int? userId;

  @override
  State<_RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends State<_RegistroForm> {
  final _descricaoCtrl = TextEditingController();
  DateTime? _dataRetorno;
  bool _marcarEncerrado = false;
  String? _localError;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      setState(() => _localError = 'Descrição é obrigatória');
      return;
    }
    setState(() => _localError = null);

    final ok = await widget.vm.registrarAtendimento(
      chamadoId: widget.chamadoId,
      descricao: descricao,
      dataRetorno: _dataRetorno ?? DateTime.now(),
      marcaEncerramento: _marcarEncerrado,
    );
    if (ok && mounted) {
      _descricaoCtrl.clear();
      setState(() {
        _dataRetorno = null;
        _marcarEncerrado = false;
      });
    }
  }

  Future<void> _assumir() async {
    if (widget.userId == null) return;
    await widget.vm.assumirChamado(
      chamadoId: widget.chamadoId,
      responsavelId: widget.userId!,
    );
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.vmState.saveError ?? _localError;

    if (widget.semResponsavel) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Nenhum atendente atribuído',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Assuma este chamado para registrar atendimentos.',
                style: TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: AppSpacing.s3),
              AppButton(
                label: 'Assumir chamado',
                loading: widget.vmState.saving,
                onPressed: widget.vmState.saving ? null : _assumir,
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Registrar Atendimento',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s3),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                color: Colors.red.shade50,
                child: Text(error,
                    style:
                        const TextStyle(color: Colors.red, fontSize: 13)),
              ),
              const SizedBox(height: AppSpacing.s3),
            ],
            AppTextArea(
              label: 'Descrição do atendimento',
              obrigatorio: true,
              controller: _descricaoCtrl,
            ),
            const SizedBox(height: AppSpacing.s3),
            AppDateTimeField(
              label: 'Data de retorno',
              value: _dataRetorno,
              onChanged: (v) => setState(() => _dataRetorno = v),
            ),
            const SizedBox(height: AppSpacing.s3),
            AppCheckboxRow(
              label: 'Marcar como encerrado',
              value: _marcarEncerrado,
              onChanged: (v) => setState(() => _marcarEncerrado = v),
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                AppButton(
                  label: 'Cancelar',
                  variant: AppButtonVariant.secondary,
                  onPressed: () {
                    _descricaoCtrl.clear();
                    setState(() {
                      _dataRetorno = null;
                      _marcarEncerrado = false;
                      _localError = null;
                    });
                    widget.vm.clearSaveError();
                  },
                ),
                const SizedBox(width: AppSpacing.s3),
                AppButton(
                  label: 'Salvar Atendimento',
                  loading: widget.vmState.saving,
                  onPressed: widget.vmState.saving ? null : _submit,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

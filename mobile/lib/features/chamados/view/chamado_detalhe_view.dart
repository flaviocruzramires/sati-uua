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
import '../../../core/widgets/forms/app_text_field.dart' show AppTextArea, AppTextField;
import '../../../core/widgets/tags/app_tag.dart';
import '../../../core/widgets/timeline/app_timeline.dart';
import '../chamado_detalhe_dto.dart';
import '../chamado_dto.dart';
import '../view_model/chamado_detalhe_view_model.dart';
import '../view_model/chamados_list_view_model.dart';
import 'widgets/anexos_widget.dart';

final _dtFmt = DateFormat('dd/MM/yyyy HH:mm');

class ChamadoDetalheView extends ConsumerWidget {
  const ChamadoDetalheView({super.key, required this.chamadoId});

  final int chamadoId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vmState = ref.watch(chamadoDetalheViewModelProvider(chamadoId));
    final vm = ref.read(chamadoDetalheViewModelProvider(chamadoId).notifier);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final isAtendente =
        user?.papel == PapelUsuario.atendente ||
        user?.papel == PapelUsuario.admin;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/chamados'),
        ),
        title:
            vmState.detalheState.whenOrNull(
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
              Text(
                'Erro ao carregar chamado',
                style: TextStyle(color: AppColors.muted),
              ),
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
          onChamadoEncerrado: () =>
              ref.invalidate(chamadosListViewModelProvider),
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
    required this.onChamadoEncerrado,
  });

  final ChamadoDetalheDto detalhe;
  final int chamadoId;
  final bool isAtendente;
  final int? userId;
  final ChamadoDetalheViewModel vm;
  final ChamadoDetalheState vmState;
  final VoidCallback onChamadoEncerrado;

  @override
  Widget build(BuildContext context) {
    final chamado = detalhe.chamado;
    final encerrado = chamado.situacao == SituacaoChamado.encerrado;
    final semResponsavel = chamado.responsavelId == null;
    final isSolicitanteProprio = !isAtendente && userId == chamado.solicitanteId;

    final resumoCard = _ResumoCard(chamado: chamado);
    final anexosCard = _AnexosCard(
      chamado: chamado,
      anexos: detalhe.anexos.where((a) => a.historicoId == null).toList(),
      vm: vm,
      userId: userId,
      isAtendente: isAtendente,
    );
    final timeline = _Timeline(historico: detalhe.historico, chamado: chamado);

    Widget? atendenteForm;
    if (!encerrado && isAtendente) {
      atendenteForm = _RegistroForm(
        chamadoId: chamadoId,
        vm: vm,
        vmState: vmState,
        semResponsavel: semResponsavel,
        userId: userId,
        onChamadoEncerrado: onChamadoEncerrado,
      );
    }

    Widget? solicitanteForm;
    if (!encerrado && isSolicitanteProprio) {
      solicitanteForm = _RetornoSolicitanteForm(
        chamadoId: chamadoId,
        vm: vm,
        vmState: vmState,
      );
    }

    final activeForm = atendenteForm ?? solicitanteForm;

    if (Breakpoints.isMobile(context)) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            resumoCard,
            const SizedBox(height: AppSpacing.s3),
            anexosCard,
            const SizedBox(height: AppSpacing.s3),
            timeline,
            if (activeForm != null) ...[
              const SizedBox(height: AppSpacing.s3),
              activeForm,
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
          const SizedBox(height: AppSpacing.s3),
          anexosCard,
          const SizedBox(height: AppSpacing.s4),
          if (activeForm != null)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 13, child: timeline),
                const SizedBox(width: AppSpacing.s4),
                Expanded(flex: 10, child: activeForm),
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
            if (chamado.envolveTerceiro) ...[
              const SizedBox(height: AppSpacing.s3),
              _TerceiroChip(nomeTerceiro: chamado.nomeTerceiro),
            ],
            const Divider(height: AppSpacing.s6),
            Text(
              'Descrição',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(chamado.descricao),
          ],
        ),
      ),
    );
  }
}

// ── Card de Anexos ────────────────────────────────────────────────────────────

class _AnexosCard extends StatelessWidget {
  const _AnexosCard({
    required this.chamado,
    required this.anexos,
    required this.vm,
    required this.userId,
    required this.isAtendente,
  });

  final ChamadoDto chamado;
  final List<AnexoDto> anexos;
  final ChamadoDetalheViewModel vm;
  final int? userId;
  final bool isAtendente;

  @override
  Widget build(BuildContext context) {
    final encerrado = chamado.situacao == SituacaoChamado.encerrado;
    final count = anexos.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.paperclip, size: 16),
                const SizedBox(width: AppSpacing.s2),
                Text(
                  'Anexos',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (count > 0) ...[
                  const SizedBox(width: AppSpacing.s2),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accent500,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            AnexosWidget(
              chamadoId: chamado.id,
              anexos: anexos,
              readOnly: encerrado,
              currentUserId: userId,
              isAtendente: isAtendente,
              onUploaded: vm.adicionarAnexo,
              onDeleted: vm.removerAnexo,
            ),
          ],
        ),
      ),
    );
  }
}

class _TerceiroChip extends StatelessWidget {
  const _TerceiroChip({required this.nomeTerceiro});

  final String? nomeTerceiro;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(LucideIcons.userX, size: 14, color: Colors.orange),
        const SizedBox(width: AppSpacing.s1),
        Text(
          'Envolve terceiro${nomeTerceiro != null ? ': $nomeTerceiro' : ''}',
          style: const TextStyle(
            color: Colors.orange,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
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
        Text(
          kicker,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
        ),
        Text(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  const _Timeline({required this.historico, required this.chamado});

  final List<ChamadoHistoricoDto> historico;
  final ChamadoDto chamado;

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
            Text(
              'Histórico de atendimento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s3),
            // Trilho reutilizável (core/widgets/timeline); o conteúdo específico
            // de chamado (autor, badges, campos) fica nos helpers abaixo.
            AppTimeline(
              entries: List.generate(historico.length, (i) {
                final h = historico[i];
                final isLast = i == historico.length - 1;
                return _entryFor(h, expandedByDefault: isLast);
              }),
            ),
          ],
        ),
      ),
    );
  }

  AppTimelineEntry _entryFor(
    ChamadoHistoricoDto item, {
    required bool expandedByDefault,
  }) {
    final isRetornoSolicitante = item.eRetornoSolicitante;
    final dotColor = item.marcaEncerramento
        ? AppColors.accent500
        : isRetornoSolicitante
            ? Colors.blue.shade400
            : AppColors.accent300;
    return AppTimelineEntry(
      dotColor: dotColor,
      dotShape: isRetornoSolicitante ? BoxShape.circle : BoxShape.rectangle,
      initiallyExpanded: expandedByDefault,
      header: _header(item, isRetornoSolicitante),
      body: _body(item, isRetornoSolicitante),
    );
  }

  Widget _header(ChamadoHistoricoDto item, bool isRetornoSolicitante) {
    final headerColor =
        isRetornoSolicitante ? Colors.blue.shade700 : AppColors.text;
    return Row(
      children: [
        if (isRetornoSolicitante) ...[
          Icon(LucideIcons.messageCircle,
              size: 12, color: Colors.blue.shade600),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.autorNome,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: headerColor,
                ),
              ),
              Text(
                _dtFmt.format(item.dataRetorno.toLocal()),
                style: TextStyle(fontSize: 11, color: AppColors.muted),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        if (item.marcaEncerramento)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.accent500,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Encerrado',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          )
        else if (isRetornoSolicitante)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'Solicitante',
              style: TextStyle(
                  color: Colors.blue.shade700,
                  fontSize: 10,
                  fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }

  Widget _body(ChamadoHistoricoDto item, bool isRetornoSolicitante) {
    return Padding(
      padding:
          const EdgeInsets.only(top: AppSpacing.s2, bottom: AppSpacing.s2),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ExpandedField(label: 'Descrição', value: item.descricao),
            const SizedBox(height: AppSpacing.s2),
            _ExpandedField(
              label: 'Data do retorno',
              value: _dtFmt.format(item.dataRetorno.toLocal()),
            ),
            if (item.dataPrevistaRetorno != null) ...[
              const SizedBox(height: AppSpacing.s2),
              _ExpandedField(
                label: 'Data prevista de retorno',
                value: DateFormat('dd/MM/yyyy')
                    .format(item.dataPrevistaRetorno!.toLocal()),
              ),
            ],
            const SizedBox(height: AppSpacing.s2),
            _ExpandedField(
              label: 'Envolve terceiro?',
              value: chamado.envolveTerceiro ? 'Sim' : 'Não',
            ),
            if (chamado.envolveTerceiro && chamado.nomeTerceiro != null) ...[
              const SizedBox(height: AppSpacing.s2),
              _ExpandedField(
                label: 'Nome do terceiro',
                value: chamado.nomeTerceiro!,
              ),
            ],
            const SizedBox(height: AppSpacing.s2),
            _ExpandedField(
              label: 'Tipo',
              value: isRetornoSolicitante
                  ? 'Retorno do solicitante'
                  : 'Atendimento',
            ),
            if (item.marcaEncerramento) ...[
              const SizedBox(height: AppSpacing.s2),
              Row(
                children: [
                  Icon(LucideIcons.checkCircle,
                      size: 14, color: AppColors.accent500),
                  const SizedBox(width: 6),
                  Text(
                    'Chamado encerrado neste registro',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accent500,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ExpandedField extends StatelessWidget {
  const _ExpandedField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.muted,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, height: 1.4)),
      ],
    );
  }
}

// ── Formulário de registro (atendente) ────────────────────────────────────────

class _RegistroForm extends StatefulWidget {
  const _RegistroForm({
    required this.chamadoId,
    required this.vm,
    required this.vmState,
    required this.semResponsavel,
    required this.userId,
    required this.onChamadoEncerrado,
  });

  final int chamadoId;
  final ChamadoDetalheViewModel vm;
  final ChamadoDetalheState vmState;
  final bool semResponsavel;
  final int? userId;
  final VoidCallback onChamadoEncerrado;

  @override
  State<_RegistroForm> createState() => _RegistroFormState();
}

class _RegistroFormState extends State<_RegistroForm> {
  final _descricaoCtrl = TextEditingController();
  final _nomeTerceiroCtrl = TextEditingController();
  DateTime? _dataRetorno;
  DateTime? _dataPrevistaRetorno;
  bool _marcarEncerrado = false;
  late bool _envolveTerceiro;
  String? _localError;

  @override
  void initState() {
    super.initState();
    final chamado =
        widget.vmState.detalheState.valueOrNull?.chamado;
    _envolveTerceiro = chamado?.envolveTerceiro ?? false;
    if (chamado?.nomeTerceiro != null) {
      _nomeTerceiroCtrl.text = chamado!.nomeTerceiro!;
    }
  }

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    _nomeTerceiroCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      setState(() => _localError = 'Descrição é obrigatória');
      return;
    }
    setState(() => _localError = null);

    final chamado = widget.vmState.detalheState.valueOrNull?.chamado;
    final nomeAtual = _nomeTerceiroCtrl.text.trim().isNotEmpty
        ? _nomeTerceiroCtrl.text.trim()
        : null;
    final terceiroMudou = _envolveTerceiro != (chamado?.envolveTerceiro ?? false) ||
        (_envolveTerceiro && nomeAtual != chamado?.nomeTerceiro);
    if (terceiroMudou) {
      await widget.vm.atualizarTerceiro(
        chamadoId: widget.chamadoId,
        envolveTerceiro: _envolveTerceiro,
        nomeTerceiro: _envolveTerceiro ? nomeAtual : null,
      );
    }

    final ok = await widget.vm.registrarAtendimento(
      chamadoId: widget.chamadoId,
      descricao: descricao,
      dataRetorno: _dataRetorno ?? DateTime.now(),
      marcaEncerramento: _marcarEncerrado,
      dataPrevistaRetorno: _dataPrevistaRetorno,
    );
    if (ok && mounted) {
      if (_marcarEncerrado) widget.onChamadoEncerrado();
      _descricaoCtrl.clear();
      setState(() {
        _dataRetorno = null;
        _dataPrevistaRetorno = null;
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
              Text(
                'Nenhum atendente atribuído',
                style: Theme.of(context).textTheme.titleMedium,
              ),
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
            Text(
              'Registrar Atendimento',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s3),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                color: Colors.red.shade50,
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
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
            AppDateField(
              label: 'Data prevista de retorno',
              value: _dataPrevistaRetorno,
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
              onChanged: (v) => setState(() => _dataPrevistaRetorno = v),
            ),
            const SizedBox(height: AppSpacing.s3),
            AppCheckboxRow(
              label: 'Envolve terceiro',
              value: _envolveTerceiro,
              onChanged: (v) => setState(() => _envolveTerceiro = v),
            ),
            if (_envolveTerceiro) ...[
              const SizedBox(height: AppSpacing.s2),
              AppTextField(
                label: 'Nome do terceiro',
                controller: _nomeTerceiroCtrl,
              ),
            ],
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
                    _nomeTerceiroCtrl.clear();
                    setState(() {
                      _dataRetorno = null;
                      _dataPrevistaRetorno = null;
                      _marcarEncerrado = false;
                      _envolveTerceiro = false;
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

// ── Formulário retorno solicitante ────────────────────────────────────────────

class _RetornoSolicitanteForm extends StatefulWidget {
  const _RetornoSolicitanteForm({
    required this.chamadoId,
    required this.vm,
    required this.vmState,
  });

  final int chamadoId;
  final ChamadoDetalheViewModel vm;
  final ChamadoDetalheState vmState;

  @override
  State<_RetornoSolicitanteForm> createState() =>
      _RetornoSolicitanteFormState();
}

class _RetornoSolicitanteFormState extends State<_RetornoSolicitanteForm> {
  final _descricaoCtrl = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      setState(() => _localError = 'Informe os dados adicionais');
      return;
    }
    setState(() => _localError = null);

    final ok = await widget.vm.enviarRetornoSolicitante(
      chamadoId: widget.chamadoId,
      descricao: descricao,
      dataRetorno: DateTime.now(),
    );
    if (ok && mounted) {
      _descricaoCtrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.vmState.saveError ?? _localError;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Informar dados adicionais',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.s1),
            Text(
              'Adicione informações extras sobre o chamado. Isso não altera a situação.',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
            const SizedBox(height: AppSpacing.s3),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                color: Colors.red.shade50,
                child: Text(
                  error,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ),
              const SizedBox(height: AppSpacing.s3),
            ],
            AppTextArea(
              label: 'Dados adicionais',
              obrigatorio: true,
              controller: _descricaoCtrl,
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
                    setState(() => _localError = null);
                    widget.vm.clearSaveError();
                  },
                ),
                const SizedBox(width: AppSpacing.s3),
                AppButton(
                  label: 'Enviar',
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

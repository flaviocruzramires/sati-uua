import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/forms/app_select.dart';
import '../../../core/widgets/forms/app_text_field.dart' show AppTextArea;
import '../view_model/abrir_chamado_view_model.dart';

class AbrirChamadoView extends ConsumerStatefulWidget {
  const AbrirChamadoView({super.key});

  @override
  ConsumerState<AbrirChamadoView> createState() => _AbrirChamadoViewState();
}

class _AbrirChamadoViewState extends ConsumerState<AbrirChamadoView> {
  final _descricaoCtrl = TextEditingController();
  int? _equipamentoId;
  int? _servicoId;
  String? _localError;

  @override
  void dispose() {
    _descricaoCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final descricao = _descricaoCtrl.text.trim();
    if (descricao.isEmpty) {
      setState(() => _localError = 'Descrição do problema é obrigatória');
      return;
    }
    setState(() => _localError = null);

    final vm = ref.read(abrirChamadoViewModelProvider.notifier);
    final ok = await vm.abrir(
      descricao: descricao,
      equipamentoId: _equipamentoId,
      servicoId: _servicoId,
    );
    if (ok && mounted) {
      final id = ref.read(abrirChamadoViewModelProvider).chamadoCriadoId;
      context.go(id != null ? '/chamados/$id' : '/chamados');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vmState = ref.watch(abrirChamadoViewModelProvider);
    final equipamentos = vmState.equipamentosCombo.valueOrNull ?? [];
    final servicos = vmState.servicosCombo.valueOrNull ?? [];
    final error = vmState.saveError ?? _localError;
    final isMobile = Breakpoints.isMobile(context);

    final form = _FormCard(
      descricaoCtrl: _descricaoCtrl,
      equipamentos: equipamentos,
      servicos: servicos,
      equipamentoId: _equipamentoId,
      servicoId: _servicoId,
      error: error,
      saving: vmState.saving,
      onEquipamentoChanged: (v) => setState(() => _equipamentoId = v),
      onServicoChanged: (v) => setState(() => _servicoId = v),
      onSubmit: _submit,
      onCancel: () => context.go('/chamados'),
      isMobile: isMobile,
    );

    if (isMobile) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft),
            onPressed: () => context.go('/chamados'),
          ),
          title: const Text('Abrir Chamado'),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          child: form,
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.divider, width: 2)),
          ),
          padding: const EdgeInsets.all(AppSpacing.s3),
          child: AppButton(
            label: 'Abrir Chamado',
            loading: vmState.saving,
            onPressed: vmState.saving ? null : _submit,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => context.go('/chamados'),
        ),
        title: const Text('Abrir Chamado'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.s6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(width: 600, child: form),
              const SizedBox(width: AppSpacing.s6),
              const SizedBox(width: 280, child: _ComoFuncionaCard()),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.descricaoCtrl,
    required this.equipamentos,
    required this.servicos,
    required this.equipamentoId,
    required this.servicoId,
    required this.error,
    required this.saving,
    required this.onEquipamentoChanged,
    required this.onServicoChanged,
    required this.onSubmit,
    required this.onCancel,
    required this.isMobile,
  });

  final TextEditingController descricaoCtrl;
  final List<ComboItem<int?>> equipamentos;
  final List<ComboItem<int?>> servicos;
  final int? equipamentoId;
  final int? servicoId;
  final String? error;
  final bool saving;
  final ValueChanged<int?> onEquipamentoChanged;
  final ValueChanged<int?> onServicoChanged;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Descreva o problema',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s1),
            Text(
              'Forneça detalhes suficientes para o atendente entender o problema.',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: AppSpacing.s4),
            if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.s3),
                color: Colors.red.shade50,
                child: Text(error!,
                    style:
                        const TextStyle(color: Colors.red, fontSize: 13)),
              ),
              const SizedBox(height: AppSpacing.s3),
            ],
            AppTextArea(
              label: 'Descrição do problema',
              obrigatorio: true,
              controller: descricaoCtrl,
              maxLines: 5,
            ),
            const SizedBox(height: AppSpacing.s3),
            if (isMobile) ...[
              AppSelect<int?>(
                label: 'Equipamento (opcional)',
                value: equipamentoId,
                items: equipamentos,
                onChanged: onEquipamentoChanged,
              ),
              const SizedBox(height: AppSpacing.s3),
              AppSelect<int?>(
                label: 'Serviço (opcional)',
                value: servicoId,
                items: servicos,
                onChanged: onServicoChanged,
              ),
            ] else
              Row(
                children: [
                  Expanded(
                    child: AppSelect<int?>(
                      label: 'Equipamento (opcional)',
                      value: equipamentoId,
                      items: equipamentos,
                      onChanged: onEquipamentoChanged,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: AppSelect<int?>(
                      label: 'Serviço (opcional)',
                      value: servicoId,
                      items: servicos,
                      onChanged: onServicoChanged,
                    ),
                  ),
                ],
              ),
            if (!isMobile) ...[
              const SizedBox(height: AppSpacing.s4),
              const Divider(),
              const SizedBox(height: AppSpacing.s3),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AppButton(
                    label: 'Cancelar',
                    variant: AppButtonVariant.secondary,
                    onPressed: onCancel,
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  AppButton(
                    label: 'Abrir Chamado',
                    loading: saving,
                    onPressed: saving ? null : onSubmit,
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

class _ComoFuncionaCard extends StatelessWidget {
  const _ComoFuncionaCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Como funciona',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s4),
            _Step(
              numero: 1,
              titulo: 'Descreva o problema',
              descricao:
                  'Informe detalhes do equipamento e do serviço relacionado.',
            ),
            const SizedBox(height: AppSpacing.s3),
            _Step(
              numero: 2,
              titulo: 'Atendente notificado',
              descricao:
                  'Um atendente de TI assumirá o chamado e entrará em contato.',
            ),
            const SizedBox(height: AppSpacing.s3),
            _Step(
              numero: 3,
              titulo: 'Acompanhe em Meus Chamados',
              descricao:
                  'Você pode acompanhar o status do chamado a qualquer momento.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.numero,
    required this.titulo,
    required this.descricao,
  });

  final int numero;
  final String titulo;
  final String descricao;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColors.accent500.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            '$numero',
            style: TextStyle(
              color: AppColors.accent500,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s2),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
              Text(descricao,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

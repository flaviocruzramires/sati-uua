import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/feedback/async_state_view.dart';
import '../../../core/widgets/forms/app_checkbox_row.dart';
import '../../../core/widgets/forms/app_text_field.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../configuracao_dto.dart';
import '../view_model/configuracoes_view_model.dart';

class ConfiguracoesView extends ConsumerWidget {
  const ConfiguracoesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final vmState = ref.watch(configuracoesViewModelProvider);
    final vm = ref.read(configuracoesViewModelProvider.notifier);

    return AppShell(
      currentRoute: '/configuracoes',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel ?? PapelUsuario.solicitante,
      title: 'Configurações',
      subtitle: 'Parâmetros do sistema',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      child: AsyncStateView<List<ConfiguracaoDto>>(
        value: vmState.listState,
        onRetry: vm.load,
        empty: () => const Center(child: Text('Nenhuma configuração disponível')),
        builder: (configs) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (vmState.saveError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, 0),
                child: Text(
                  vmState.saveError!,
                  style: const TextStyle(color: Color(0xFFB91C1C)),
                ),
              ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.s4),
                itemCount: configs.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.s3),
                itemBuilder: (_, i) => _ConfiguracaoCard(
                  config: configs[i],
                  saving: vmState.saving,
                  onSave: (valor) => vm.save(configs[i].chave, valor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConfiguracaoCard extends StatefulWidget {
  const _ConfiguracaoCard({
    required this.config,
    required this.saving,
    required this.onSave,
  });

  final ConfiguracaoDto config;
  final bool saving;
  final Future<bool> Function(String valor) onSave;

  @override
  State<_ConfiguracaoCard> createState() => _ConfiguracaoCardState();
}

class _ConfiguracaoCardState extends State<_ConfiguracaoCard> {
  late TextEditingController _ctrl;
  late bool _boolValue;
  bool _dirty = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.config.valor);
    _boolValue = widget.config.valor == 'true';
    _ctrl.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(_ConfiguracaoCard old) {
    super.didUpdateWidget(old);
    if (old.config.valor != widget.config.valor && !_dirty) {
      _ctrl.text = widget.config.valor;
      _boolValue = widget.config.valor == 'true';
    }
  }

  void _onTextChanged() => setState(() => _dirty = true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _salvar() async {
    final valor =
        widget.config.tipo == 'bool' ? _boolValue.toString() : _ctrl.text.trim();
    final ok = await widget.onSave(valor);
    if (ok) setState(() => _dirty = false);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppColors.neutral300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  widget.config.chave,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontFamily: 'monospace',
                        color: AppColors.navy,
                      ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.neutral300),
                  ),
                  child: Text(
                    widget.config.tipo,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
                ),
              ],
            ),
            if (widget.config.descricao != null) ...[
              const SizedBox(height: AppSpacing.s1),
              Text(
                widget.config.descricao!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: AppColors.muted),
              ),
            ],
            const SizedBox(height: AppSpacing.s3),
            if (widget.config.tipo == 'bool')
              AppCheckboxRow(
                label: 'Habilitado',
                value: _boolValue,
                onChanged: (v) => setState(() {
                  _boolValue = v;
                  _dirty = true;
                }),
              )
            else
              AppTextField(
                label: 'Valor',
                controller: _ctrl,
                keyboardType: widget.config.tipo == 'int'
                    ? TextInputType.number
                    : TextInputType.text,
                enabled: !widget.saving,
              ),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                AppButton(
                  label: 'Salvar',
                  onPressed: (_dirty && !widget.saving) ? _salvar : null,
                ),
                if (widget.config.atualizadoPorNome != null) ...[
                  const SizedBox(width: AppSpacing.s3),
                  Text(
                    'Atualizado por ${widget.config.atualizadoPorNome}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.muted),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

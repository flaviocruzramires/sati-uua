import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/domain/enums.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/breakpoints.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/forms/app_segmented_control.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/surfaces/app_card.dart';
import '../permissao_dto.dart';
import '../rotina_repository.dart';
import '../view_model/permissionamento_view_model.dart';

/// Rotina 12 — tela do Admin para montar a matriz papel × rotina.
class PermissionamentoView extends ConsumerWidget {
  const PermissionamentoView({super.key});

  static const _papeis = [
    SegmentedOption(PapelUsuario.solicitante, 'Solicitante'),
    SegmentedOption(PapelUsuario.atendente, 'Atendente'),
    SegmentedOption(PapelUsuario.gerencia, 'Gerência'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final st = ref.watch(permissionamentoViewModelProvider);
    final vm = ref.read(permissionamentoViewModelProvider.notifier);

    Future<void> onSalvar() async {
      final ok = await vm.salvar();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(ok ? 'Permissões salvas' : 'Erro ao salvar permissões'),
          backgroundColor: ok ? AppColors.green : Colors.red,
        ),
      );
    }

    final isMobile = Breakpoints.isMobile(context);

    return AppShell(
      currentRoute: '/permissionamento',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel,
      title: 'Permissionamento',
      subtitle: 'Defina o que cada papel pode fazer em cada rotina',
      onNavigate: (route) => context.go(route),
      onLogout: () {},
      actions: [
        AppButton(
          label: 'Descartar',
          variant: AppButtonVariant.secondary,
          centerLabel: true,
          onPressed: st.dirty && !st.saving ? vm.descartar : null,
        ),
        const SizedBox(width: AppSpacing.s2),
        AppButton(
          label: 'Salvar',
          icon: LucideIcons.save,
          loading: st.saving,
          onPressed: st.dirty ? onSalvar : null,
        ),
      ],
      child: Builder(
        builder: (context) {
          if (st.carregando && st.rotinas.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (st.erro != null && st.rotinas.isEmpty) {
            return _ErroBox(erro: st.erro!, onRetry: vm.descartar);
          }

          final rows = _buildRows(st.rotinas);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _ContextoCard(
                papel: st.papel,
                dirty: st.dirty,
                onPapel: vm.selecionarPapel,
              ),
              Expanded(
                child: Stack(
                  children: [
                    isMobile
                        ? _MobileList(rows: rows, st: st, vm: vm)
                        : _DesktopTable(rows: rows, st: st, vm: vm),
                    if (st.carregando)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Color(0x66FFFFFF),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Modelo de linha para a UI ────────────────────────────────────────────────

class _RowVM {
  const _RowVM.group(this.nome)
      : isGroup = true,
        rotina = null;
  const _RowVM.leaf(RotinaDto this.rotina)
      : isGroup = false,
        nome = '';

  final bool isGroup;
  final String nome;
  final RotinaDto? rotina;
}

List<_RowVM> _buildRows(List<RotinaDto> tree) {
  final rows = <_RowVM>[];
  for (final r in tree) {
    if (r.isPai) {
      rows.add(_RowVM.group(r.nome));
      for (final f in r.filhos) {
        rows.add(_RowVM.leaf(f));
      }
    } else {
      rows.add(_RowVM.leaf(r));
    }
  }
  return rows;
}

bool _showIncluir(RotinaDto r) => r.isCrud;
bool _showAlterar(RotinaDto r) => r.isCrud && !r.isChamado;
bool _showExcluir(RotinaDto r) => r.isCrud && !r.isChamado;

// ── Card de contexto (papel + regras + tag) ──────────────────────────────────

class _ContextoCard extends StatelessWidget {
  const _ContextoCard({
    required this.papel,
    required this.dirty,
    required this.onPapel,
  });

  final PapelUsuario papel;
  final bool dirty;
  final ValueChanged<PapelUsuario> onPapel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s4,
        AppSpacing.s2,
      ),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Papel',
                  style: Theme.of(context)
                      .textTheme
                      .labelSmall
                      ?.copyWith(color: AppColors.label),
                ),
                const Spacer(),
                _DirtyTag(dirty: dirty),
              ],
            ),
            const SizedBox(height: AppSpacing.s2),
            AppSegmentedControl<PapelUsuario>(
              options: PermissionamentoView._papeis,
              value: papel,
              onChanged: onPapel,
            ),
            const SizedBox(height: AppSpacing.s2),
            Text(
              'O Admin tem acesso total e não é configurável. Sem "Ver", as '
              'demais ações ficam travadas; Dashboard e Relatórios só têm '
              '"Ver"; rotinas de Chamado só têm "Ver" e "Incluir".',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}

class _DirtyTag extends StatelessWidget {
  const _DirtyTag({required this.dirty});
  final bool dirty;

  @override
  Widget build(BuildContext context) {
    final bg = dirty ? AppColors.accent100 : AppColors.green100;
    final fg = dirty ? AppColors.accent700 : AppColors.green700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      color: bg,
      child: Text(
        dirty ? 'Alterações não salvas' : 'Tudo salvo',
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ── Desktop: tabela ──────────────────────────────────────────────────────────

const _kColW = 104.0;

class _DesktopTable extends StatelessWidget {
  const _DesktopTable({required this.rows, required this.st, required this.vm});

  final List<_RowVM> rows;
  final PermissionamentoState st;
  final PermissionamentoViewModel vm;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.s4,
        AppSpacing.s2,
        AppSpacing.s4,
        AppSpacing.s4,
      ),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            _headerRow(context),
            for (final row in rows)
              row.isGroup
                  ? _groupRow(context, row.nome)
                  : _leafRow(context, row.rotina!),
          ],
        ),
      ),
    );
  }

  Widget _headerRow(BuildContext context) {
    Widget h(String t) => SizedBox(
          width: _kColW,
          child: Text(
            t,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          ),
        );
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: Row(
        children: [
          const Expanded(
            child: Text('Rotina',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
          ),
          h('Visualização'),
          h('Inclusão'),
          h('Alteração'),
          h('Exclusão'),
        ],
      ),
    );
  }

  Widget _groupRow(BuildContext context, String nome) {
    return Container(
      width: double.infinity,
      color: AppColors.neutral100,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: AppSpacing.s2,
      ),
      child: Text(nome,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
    );
  }

  Widget _leafRow(BuildContext context, RotinaDto r) {
    final perm = st.permissao(r.id);
    final lock = !perm.ver;
    Widget cell(bool show, bool value, bool disabled, AcaoPermissao acao) {
      return SizedBox(
        width: _kColW,
        child: Center(
          child: show
              ? _Chk(
                  value: value,
                  disabled: disabled,
                  onChanged: (v) => vm.alternar(r.id, acao, v),
                )
              : const _Dash(),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s3,
        vertical: 4,
      ),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.neutral200, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 26),
              child: Text(r.nome, style: const TextStyle(fontSize: 13)),
            ),
          ),
          cell(true, perm.ver, false, AcaoPermissao.ver),
          cell(_showIncluir(r), perm.incluir, lock, AcaoPermissao.incluir),
          cell(_showAlterar(r), perm.alterar, lock, AcaoPermissao.alterar),
          cell(_showExcluir(r), perm.excluir, lock, AcaoPermissao.excluir),
        ],
      ),
    );
  }
}

// ── Mobile: cards ────────────────────────────────────────────────────────────

class _MobileList extends StatelessWidget {
  const _MobileList({required this.rows, required this.st, required this.vm});

  final List<_RowVM> rows;
  final PermissionamentoState st;
  final PermissionamentoViewModel vm;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.s3),
      itemCount: rows.length,
      separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.s2),
      itemBuilder: (_, i) {
        final row = rows[i];
        if (row.isGroup) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.s2),
            child: Text(
              row.nome.toUpperCase(),
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(color: AppColors.label, letterSpacing: 0.8),
            ),
          );
        }
        final r = row.rotina!;
        final perm = st.permissao(r.id);
        final lock = !perm.ver;
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r.nome,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: AppSpacing.s2),
              Wrap(
                spacing: AppSpacing.s3,
                runSpacing: AppSpacing.s1,
                children: [
                  _CheckLabel(
                    label: 'Ver',
                    value: perm.ver,
                    onChanged: (v) => vm.alternar(r.id, AcaoPermissao.ver, v),
                  ),
                  if (_showIncluir(r))
                    _CheckLabel(
                      label: 'Incluir',
                      value: perm.incluir,
                      disabled: lock,
                      onChanged: (v) =>
                          vm.alternar(r.id, AcaoPermissao.incluir, v),
                    ),
                  if (_showAlterar(r))
                    _CheckLabel(
                      label: 'Alterar',
                      value: perm.alterar,
                      disabled: lock,
                      onChanged: (v) =>
                          vm.alternar(r.id, AcaoPermissao.alterar, v),
                    ),
                  if (_showExcluir(r))
                    _CheckLabel(
                      label: 'Excluir',
                      value: perm.excluir,
                      disabled: lock,
                      onChanged: (v) =>
                          vm.alternar(r.id, AcaoPermissao.excluir, v),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Peças reutilizáveis ──────────────────────────────────────────────────────

class _Chk extends StatelessWidget {
  const _Chk({
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      height: 24,
      child: Checkbox(
        value: value,
        activeColor: AppColors.navy,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        onChanged: disabled ? null : (v) => onChanged(v ?? false),
      ),
    );
  }
}

class _CheckLabel extends StatelessWidget {
  const _CheckLabel({
    required this.label,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });

  final String label;
  final bool value;
  final bool disabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.4 : 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Chk(value: value, disabled: disabled, onChanged: onChanged),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 13)),
        ],
      ),
    );
  }
}

class _Dash extends StatelessWidget {
  const _Dash();
  @override
  Widget build(BuildContext context) =>
      const Text('—', style: TextStyle(color: AppColors.neutral400));
}

class _ErroBox extends StatelessWidget {
  const _ErroBox({required this.erro, required this.onRetry});
  final Object erro;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Erro ao carregar permissões: $erro',
              textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.s3),
          AppButton(label: 'Tentar novamente', onPressed: onRetry),
        ],
      ),
    );
  }
}

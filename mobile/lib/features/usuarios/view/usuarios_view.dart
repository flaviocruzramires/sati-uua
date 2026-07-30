import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/current_user_provider.dart';
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
import '../../../core/widgets/forms/app_segmented_control.dart';
import '../../../core/widgets/forms/app_text_field.dart';
import '../../../core/widgets/listing/app_card_list_item.dart';
import '../../../core/widgets/listing/app_data_table.dart';
import '../../../core/widgets/listing/filter_bar.dart';
import '../../../core/widgets/listing/pagination_bar.dart';
import '../../../core/widgets/modals/app_side_panel_form.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../../../core/widgets/tags/app_tag.dart';
import '../usuario_dto.dart';
import '../view_model/usuarios_view_model.dart';

class UsuariosView extends ConsumerWidget {
  const UsuariosView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final vmState = ref.watch(usuariosViewModelProvider);
    final vm = ref.read(usuariosViewModelProvider.notifier);

    final setoresCombo = vmState.setoresCombo.valueOrNull ?? [];
    final listData = vmState.listState.valueOrNull?.data ?? const <UsuarioDto>[];
    final selected = vmState.selectedUser(listData);

    final filtroPapelItems = [
      const ComboItem<PapelUsuario?>(null, 'Todos os papéis'),
      const ComboItem<PapelUsuario?>(PapelUsuario.admin, 'Admin'),
      const ComboItem<PapelUsuario?>(PapelUsuario.atendente, 'Atendente'),
      const ComboItem<PapelUsuario?>(PapelUsuario.solicitante, 'Solicitante'),
    ];

    // Abre o formulário: no mobile, push como rota; no desktop, seleciona no painel
    void openNew() {
      if (Breakpoints.isMobile(context)) {
        Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _UsuarioForm(
              setoresCombo: setoresCombo,
              saving: vmState.saving,
              saveError: vmState.saveError,
              onCreate: ({required nome, required email, required login,
                required senha, required setorId, required papel}) async {
                final ok = await vm.create(
                  nome: nome, email: email, login: login,
                  senha: senha, setorId: setorId, papel: papel,
                );
                if (ok && context.mounted) Navigator.of(context).pop();
              },
              onCancel: () { vm.clearSaveError(); Navigator.of(context).pop(); },
            ),
        ));
      } else {
        vm.selectUser(-1);
      }
    }

    void openEdit(UsuarioDto u) {
      if (Breakpoints.isMobile(context)) {
        Navigator.of(context).push(MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _UsuarioForm(
              usuario: u,
              setoresCombo: setoresCombo,
              saving: vmState.saving,
              saveError: vmState.saveError,
              onUpdate: ({required nome, required email, String? senha,
                required setorId, required papel, required ativo}) async {
                final ok = await vm.update(
                  id: u.id, nome: nome, email: email,
                  setorId: setorId, papel: papel, ativo: ativo, senha: senha,
                );
                if (ok && context.mounted) Navigator.of(context).pop();
              },
              onCancel: () { vm.clearSaveError(); Navigator.of(context).pop(); },
            ),
        ));
      } else {
        vm.selectUser(u.id);
      }
    }

    return AppShell(
      currentRoute: '/usuarios',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel ?? PapelUsuario.solicitante,
      title: 'Usuários',
      subtitle: 'Gestão de usuários do sistema',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      actions: [
        AppButton(label: '+ Novo Usuário', onPressed: openNew),
      ],
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FilterBar(
                  filters: [
                    SizedBox(
                      width: 200,
                      child: AppSelect<PapelUsuario?>(
                        label: 'Papel',
                        value: vmState.filtroPapel,
                        items: filtroPapelItems,
                        onChanged: vm.setFiltroPapel,
                      ),
                    ),
                  ],
                  trailing: vmState.listState.whenOrNull(
                    data: (r) => Text(
                      '${r.total} usuário${r.total != 1 ? 's' : ''}',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ),
                ),
                Expanded(
                  child: AsyncStateView<PaginatedResult<UsuarioDto>>(
                    value: vmState.listState,
                    onRetry: vm.load,
                    empty: () => const Center(
                        child: Text('Nenhum usuário encontrado')),
                    builder: (result) => Breakpoints.isMobile(context)
                        ? _MobileList(
                            result: result,
                            onEdit: openEdit,
                            onPageChange: vm.setPage,
                            currentPage: vmState.page,
                            pageSize: vmState.pageSize,
                          )
                        : _DesktopTable(
                            result: result,
                            selectedId: vmState.selectedId,
                            onSelect: (u) => vm.selectUser(u.id),
                            onEdit: openEdit,
                            onPageChange: vm.setPage,
                            currentPage: vmState.page,
                            pageSize: vmState.pageSize,
                          ),
                  ),
                ),
              ],
            ),
          ),
          // Painel lateral desktop
          if (!Breakpoints.isMobile(context) && vmState.selectedId != null)
            Container(
              decoration: const BoxDecoration(
                border: Border(
                    left: BorderSide(color: AppColors.divider, width: 2)),
              ),
              child: _UsuarioForm(
                usuario: vmState.selectedId == -1 ? null : selected,
                setoresCombo: setoresCombo,
                saving: vmState.saving,
                saveError: vmState.saveError,
                onCreate: ({required nome, required email, required login,
                  required senha, required setorId, required papel}) async {
                  final ok = await vm.create(
                    nome: nome, email: email, login: login,
                    senha: senha, setorId: setorId, papel: papel,
                  );
                  if (ok) vm.selectUser(null);
                },
                onUpdate: ({required nome, required email, String? senha,
                  required setorId, required papel, required ativo}) async {
                  final ok = await vm.update(
                    id: selected!.id, nome: nome, email: email,
                    setorId: setorId, papel: papel, ativo: ativo, senha: senha,
                  );
                  if (ok) vm.selectUser(null);
                },
                onCancel: () { vm.clearSaveError(); vm.selectUser(null); },
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
    required this.selectedId,
    required this.onSelect,
    required this.onEdit,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<UsuarioDto> result;
  final int? selectedId;
  final ValueChanged<UsuarioDto> onSelect;
  final ValueChanged<UsuarioDto> onEdit;
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
            child: AppDataTable<UsuarioDto>(
              columns: const ['Nome', 'E-mail', 'Setor', 'Papel', 'Status'],
              rows: result.data,
              onRowTap: onSelect,
              rowBuilder: (u) => [
                Text(u.nome,
                    style: u.id == selectedId
                        ? const TextStyle(fontWeight: FontWeight.w700)
                        : null),
                Text(u.email),
                Text(u.setorNome ?? '—'),
                PapelUsuarioTag(papel: u.papel),
                AtivoTag(
                    status:
                        u.ativo ? StatusAtivo.ativo : StatusAtivo.inativo),
              ],
              actionsBuilder: (u) => [
                IconActionButton(
                  icon: LucideIcons.pencil,
                  tooltip: 'Editar',
                  onPressed: () => onEdit(u),
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
    required this.onEdit,
    required this.onPageChange,
    required this.currentPage,
    required this.pageSize,
  });

  final PaginatedResult<UsuarioDto> result;
  final ValueChanged<UsuarioDto> onEdit;
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
            separatorBuilder: (_, __) =>
                const SizedBox(height: AppSpacing.s2),
            itemBuilder: (_, i) {
              final u = result.data[i];
              return AppCardListItem(
                titulo: u.nome,
                metaLines: [
                  u.email,
                  if (u.setorNome != null) u.setorNome!,
                ],
                tagSlot: Row(mainAxisSize: MainAxisSize.min, children: [
                  PapelUsuarioTag(papel: u.papel),
                  const SizedBox(width: AppSpacing.s1),
                  IconActionButton(
                    icon: LucideIcons.pencil,
                    tooltip: 'Editar',
                    onPressed: () => onEdit(u),
                  ),
                ]),
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

// ── Formulário único (desktop: painel lateral / mobile: tela cheia via AppSidePanelForm) ──

typedef _OnCreate = Future<void> Function({
  required String nome,
  required String email,
  required String login,
  required String senha,
  required int setorId,
  required PapelUsuario papel,
});

typedef _OnUpdate = Future<void> Function({
  required String nome,
  required String email,
  String? senha,
  required int setorId,
  required PapelUsuario papel,
  required bool ativo,
});

class _UsuarioForm extends StatefulWidget {
  const _UsuarioForm({
    required this.setoresCombo,
    required this.saving,
    required this.onCancel,
    this.usuario,
    this.saveError,
    this.onCreate,
    this.onUpdate,
  });

  final UsuarioDto? usuario;
  final List<ComboItem<int>> setoresCombo;
  final bool saving;
  final String? saveError;
  final VoidCallback onCancel;
  final _OnCreate? onCreate;
  final _OnUpdate? onUpdate;

  @override
  State<_UsuarioForm> createState() => _UsuarioFormState();
}

class _UsuarioFormState extends State<_UsuarioForm> {
  late final TextEditingController _nomeCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _loginCtrl;
  final TextEditingController _senhaCtrl = TextEditingController();
  int? _setorId;
  PapelUsuario _papel = PapelUsuario.solicitante;
  bool _ativo = true;
  String? _localError;

  bool get _isEdit => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nomeCtrl = TextEditingController(text: u?.nome ?? '');
    _emailCtrl = TextEditingController(text: u?.email ?? '');
    _loginCtrl = TextEditingController(text: u?.login ?? '');
    _setorId = u?.setorId;
    _papel = u?.papel ?? PapelUsuario.solicitante;
    _ativo = u?.ativo ?? true;
  }

  @override
  void dispose() {
    _nomeCtrl.dispose();
    _emailCtrl.dispose();
    _loginCtrl.dispose();
    _senhaCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final nome = _nomeCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final login = _loginCtrl.text.trim();
    final senha = _senhaCtrl.text;

    if (nome.isEmpty || email.isEmpty || login.isEmpty) {
      setState(() => _localError = 'Nome, e-mail e login são obrigatórios');
      return;
    }
    if (!_isEdit && senha.length < 8) {
      setState(() => _localError = 'Senha deve ter no mínimo 8 caracteres');
      return;
    }
    if (_isEdit && senha.isNotEmpty && senha.length < 8) {
      setState(() => _localError = 'Senha deve ter no mínimo 8 caracteres');
      return;
    }
    if (_setorId == null) {
      setState(() => _localError = 'Setor é obrigatório');
      return;
    }
    setState(() => _localError = null);

    if (_isEdit) {
      widget.onUpdate?.call(
        nome: nome,
        email: email,
        senha: senha.isEmpty ? null : senha,
        setorId: _setorId!,
        papel: _papel,
        ativo: _ativo,
      );
    } else {
      widget.onCreate?.call(
        nome: nome,
        email: email,
        login: login,
        senha: senha,
        setorId: _setorId!,
        papel: _papel,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.saveError ?? _localError;
    return AppSidePanelForm(
      title: _isEdit ? 'Editar Usuário' : 'Novo Usuário',
      saving: widget.saving,
      onCancel: widget.onCancel,
      onSave: _submit,
      fields: [
        if (error != null)
          Container(
            padding: const EdgeInsets.all(AppSpacing.s3),
            color: Colors.red.shade50,
            child: Text(error,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
        AppTextField(
            label: 'Nome completo', obrigatorio: true, controller: _nomeCtrl),
        AppTextField(
          label: 'E-mail',
          obrigatorio: true,
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
        ),
        AppTextField(
            label: 'Login', obrigatorio: !_isEdit, controller: _loginCtrl),
        AppTextField(
          label:
              _isEdit ? 'Senha (deixe em branco para manter)' : 'Senha',
          obrigatorio: !_isEdit,
          controller: _senhaCtrl,
          obscure: true,
        ),
        AppSelect<int>(
          label: 'Setor',
          obrigatorio: true,
          value: _setorId,
          items: widget.setoresCombo,
          onChanged: (v) => setState(() => _setorId = v),
        ),
        AppSegmentedControl<PapelUsuario>(
          value: _papel,
          options: const [
            SegmentedOption(PapelUsuario.solicitante, 'Solicitante'),
            SegmentedOption(PapelUsuario.atendente, 'Atendente'),
            SegmentedOption(PapelUsuario.admin, 'Admin'),
          ],
          onChanged: (v) => setState(() => _papel = v),
        ),
        if (_isEdit)
          AppCheckboxRow(
            label: 'Ativo',
            value: _ativo,
            onChanged: (v) => setState(() => _ativo = v),
          ),
      ],
    );
  }
}

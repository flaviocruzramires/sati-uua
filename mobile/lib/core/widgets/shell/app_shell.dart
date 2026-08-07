import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../auth/permissoes_provider.dart';
import '../../domain/enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/breakpoints.dart';
import '../../../features/auth/view_model/login_view_model.dart';
import '../../../features/notificacoes/notificacoes_view_model.dart';
import 'nav_item.dart';
import 'user_footer_tile.dart';

// Definição de uma entrada de navegação
class NavEntry {
  const NavEntry({
    required this.icon,
    required this.label,
    required this.route,
    this.chave,
    this.adminOnly = false,
    this.group,
    this.bottomNavIndex,
  });

  final IconData icon;
  final String label;
  final String route;

  /// Chave da rotina no permissionamento (rotina 13). A visibilidade do item
  /// passa a ser `podeVer(chave)`. `null` = sempre visível.
  final String? chave;

  /// Itens fora da matriz de permissões (ex.: Permissionamento) — só Admin.
  final bool adminOnly;

  final String? group; // null = raiz, 'CADASTROS', 'ANÁLISE', 'ADMINISTRAÇÃO'
  final int? bottomNavIndex; // qual aba do bottom nav representa
}

// Todas as entradas de navegação do app. A visibilidade vem da matriz de
// permissões (rotina 13) via `chave`; Sair e Notificações ficam fora (fixos).
const kNavEntries = [
  NavEntry(
    icon: LucideIcons.layoutGrid,
    label: 'Dashboard',
    route: '/',
    chave: 'dashboard',
    bottomNavIndex: 0,
  ),
  NavEntry(
    icon: LucideIcons.ticket,
    label: 'Chamados',
    route: '/chamados',
    chave: 'chamados.consulta',
    bottomNavIndex: 1,
  ),
  NavEntry(
    icon: LucideIcons.building2,
    label: 'Setores',
    route: '/setores',
    group: 'CADASTROS',
    chave: 'cadastros.setores',
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.layers,
    label: 'Tipos de Equipamento',
    route: '/tipos-equipamento',
    group: 'CADASTROS',
    chave: 'cadastros.tipos',
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.monitor,
    label: 'Equipamentos',
    route: '/equipamentos',
    group: 'CADASTROS',
    chave: 'cadastros.equip',
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.slidersHorizontal,
    label: 'Serviços',
    route: '/servicos',
    group: 'CADASTROS',
    chave: 'cadastros.servicos',
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.users,
    label: 'Usuários',
    route: '/usuarios',
    group: 'CADASTROS',
    chave: 'cadastros.usuarios',
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.barChart2,
    label: 'Relatórios',
    route: '/relatorios',
    group: 'ANÁLISE',
    chave: 'analise.relatorios',
    bottomNavIndex: 3,
  ),
  NavEntry(
    icon: LucideIcons.settings,
    label: 'Configurações',
    route: '/configuracoes',
    group: 'ANÁLISE',
    chave: 'analise.config',
    bottomNavIndex: 3,
  ),
  NavEntry(
    icon: LucideIcons.shield,
    label: 'Permissionamento',
    route: '/permissionamento',
    group: 'ADMINISTRAÇÃO',
    adminOnly: true,
    bottomNavIndex: 3,
  ),
];

class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.nomeUsuario,
    this.papelUsuario,
    required this.onNavigate,
    required this.onLogout,
    this.title = '',
    this.subtitle,
    this.actions,
  });

  final Widget child;
  final String currentRoute;
  final String nomeUsuario;
  final PapelUsuario? papelUsuario;
  final ValueChanged<String> onNavigate;
  final VoidCallback onLogout;
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  VoidCallback _buildLogout(BuildContext context, WidgetRef ref) {
    return () async {
      await ref.read(loginViewModelProvider.notifier).logout();
      if (context.mounted) context.go('/login');
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final perm = ref.watch(permissoesHelperProvider);
    bool visivel(NavEntry e) => e.adminOnly
        ? perm.isAdmin
        : (e.chave == null ? true : perm.podeVer(e.chave!));

    final effectiveShell = _ShellData(
      shell: this,
      onLogout: _buildLogout(context, ref),
      visibleEntries: kNavEntries.where(visivel).toList(),
    );
    if (Breakpoints.isMobile(context)) {
      return _MobileShell(shell: effectiveShell);
    }
    return _DesktopShell(shell: effectiveShell);
  }
}

class _ShellData {
  const _ShellData({
    required this.shell,
    required this.onLogout,
    required this.visibleEntries,
  });
  final AppShell shell;
  final VoidCallback onLogout;
  final List<NavEntry> visibleEntries;

  Widget get child => shell.child;
  String get currentRoute => shell.currentRoute;
  String get nomeUsuario => shell.nomeUsuario;
  PapelUsuario? get papelUsuario => shell.papelUsuario;
  ValueChanged<String> get onNavigate => shell.onNavigate;
  String get title => shell.title;
  String? get subtitle => shell.subtitle;
  List<Widget>? get actions => shell.actions;
}

// ── Desktop ──────────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.shell});
  final _ShellData shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Row(
        children: [
          _Sidebar(shell: shell),
          Expanded(
            child: Column(
              children: [
                _Topbar(shell: shell),
                Expanded(child: shell.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.shell, this.onNavigate});
  final _ShellData shell;
  final VoidCallback? onNavigate;

  @override
  Widget build(BuildContext context) {
    final grouped = <String?, List<NavEntry>>{};
    for (final e in shell.visibleEntries) {
      (grouped[e.group] ??= []).add(e);
    }

    return Container(
      width: 248,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.divider, width: 2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Marca
          Container(
            height: 64,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 2),
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    'assets/images/logo_sati_uua.jpg',
                    width: 34,
                    height: 34,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: AppSpacing.s2),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SATI-UUA',
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(fontSize: 14),
                    ),
                    Text(
                      'UEMS AQUIDAUANA',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.08 * 10,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Itens
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Itens raiz (sem grupo)
                  ...(grouped[null] ?? []).map(
                    (e) => SidebarNavItem(
                      icon: e.icon,
                      label: e.label,
                      active: shell.currentRoute == e.route,
                      onTap: () {
                        onNavigate?.call();
                        shell.onNavigate(e.route);
                      },
                    ),
                  ),
                  // Grupos
                  ...grouped.entries
                      .where((en) => en.key != null)
                      .map(
                        (en) => SidebarNavGroup(
                          label: en.key!,
                          children: en.value
                              .map(
                                (e) => SidebarNavItem(
                                  icon: e.icon,
                                  label: e.label,
                                  active: shell.currentRoute == e.route,
                                  onTap: () {
                                    onNavigate?.call();
                                    shell.onNavigate(e.route);
                                  },
                                ),
                              )
                              .toList(),
                        ),
                      ),
                ],
              ),
            ),
          ),
          // Rodapé
          UserFooterTile(
            nome: shell.nomeUsuario,
            papel: shell.papelUsuario,
            onLogout: shell.onLogout,
          ),
        ],
      ),
    );
  }
}

class _Topbar extends StatelessWidget {
  const _Topbar({required this.shell});
  final _ShellData shell;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      decoration: const BoxDecoration(
        color: AppColors.bg,
        border: Border(bottom: BorderSide(color: AppColors.divider, width: 2)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shell.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                if (shell.subtitle != null)
                  Text(
                    shell.subtitle!,
                    style: Theme.of(
                      context,
                    ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
                  ),
              ],
            ),
          ),
          if (shell.actions != null)
            Row(mainAxisSize: MainAxisSize.min, children: shell.actions!),
          const SizedBox(width: AppSpacing.s3),
          const _BellButton(),
        ],
      ),
    );
  }
}

// ── Bell button with badge ────────────────────────────────────────────────────

class _BellButton extends ConsumerWidget {
  const _BellButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countAsync = ref.watch(notificacoesBadgeProvider);
    final count = countAsync.valueOrNull ?? 0;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(LucideIcons.bell, size: 20, color: AppColors.neutral600),
          onPressed: () => context.go('/notificacoes'),
          tooltip: 'Notificações',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
        if (count > 0)
          Positioned(
            top: -2,
            right: -2,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}

// ── Mobile ───────────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.shell});
  final _ShellData shell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      drawer: Builder(
        builder: (ctx) => Drawer(
          backgroundColor: AppColors.surface,
          width: 280,
          child: SafeArea(
            child: _Sidebar(
              shell: shell,
              onNavigate: () => Navigator.of(ctx).pop(),
            ),
          ),
        ),
      ),
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 2),
        ),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu, color: AppColors.neutral700),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
            tooltip: 'Menu',
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              shell.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (shell.subtitle != null)
              Text(
                shell.subtitle!,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: AppColors.muted),
              ),
          ],
        ),
        actions: [
          if (shell.actions != null) ...shell.actions!,
          const _BellButton(),
          const SizedBox(width: AppSpacing.s3),
        ],
      ),
      body: shell.child,
    );
  }
}

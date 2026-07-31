import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../domain/enums.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../theme/breakpoints.dart';
import 'bottom_nav_bar.dart';
import 'nav_item.dart';
import 'user_footer_tile.dart';

// Definição de uma entrada de navegação
class NavEntry {
  const NavEntry({
    required this.icon,
    required this.label,
    required this.route,
    this.visibleForPapeis = const [],
    this.group,
    this.bottomNavIndex,
  });

  final IconData icon;
  final String label;
  final String route;
  final List<PapelUsuario> visibleForPapeis;
  final String? group; // null = raiz, 'CADASTROS', 'ANÁLISE'
  final int? bottomNavIndex; // qual aba do bottom nav representa
}

// Todas as entradas de navegação do app
const kNavEntries = [
  NavEntry(
    icon: LucideIcons.layoutGrid,
    label: 'Dashboard',
    route: '/',
    bottomNavIndex: 0,
  ),
  NavEntry(
    icon: LucideIcons.ticket,
    label: 'Chamados',
    route: '/chamados',
    bottomNavIndex: 1,
  ),
  NavEntry(
    icon: LucideIcons.building2,
    label: 'Setores',
    route: '/setores',
    group: 'CADASTROS',
    visibleForPapeis: [PapelUsuario.admin],
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.layers,
    label: 'Tipos de Equipamento',
    route: '/tipos-equipamento',
    group: 'CADASTROS',
    visibleForPapeis: [PapelUsuario.admin, PapelUsuario.atendente],
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.monitor,
    label: 'Equipamentos',
    route: '/equipamentos',
    group: 'CADASTROS',
    visibleForPapeis: [PapelUsuario.admin, PapelUsuario.atendente],
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.slidersHorizontal,
    label: 'Serviços',
    route: '/servicos',
    group: 'CADASTROS',
    visibleForPapeis: [PapelUsuario.admin, PapelUsuario.atendente],
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.users,
    label: 'Usuários',
    route: '/usuarios',
    group: 'CADASTROS',
    visibleForPapeis: [PapelUsuario.admin],
    bottomNavIndex: 2,
  ),
  NavEntry(
    icon: LucideIcons.barChart2,
    label: 'Relatórios',
    route: '/relatorios',
    group: 'ANÁLISE',
    bottomNavIndex: 3,
  ),
  NavEntry(
    icon: LucideIcons.settings,
    label: 'Configurações',
    route: '/configuracoes',
    group: 'ANÁLISE',
    visibleForPapeis: [PapelUsuario.admin],
    bottomNavIndex: 3,
  ),
];

class AppShell extends StatelessWidget {
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

  @override
  Widget build(BuildContext context) {
    if (Breakpoints.isMobile(context)) {
      return _MobileShell(shell: this);
    }
    return _DesktopShell(shell: this);
  }
}

// ── Desktop ──────────────────────────────────────────────────────────────────

class _DesktopShell extends StatelessWidget {
  const _DesktopShell({required this.shell});
  final AppShell shell;

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
  const _Sidebar({required this.shell});
  final AppShell shell;

  @override
  Widget build(BuildContext context) {
    final grouped = <String?, List<NavEntry>>{};
    for (final e in kNavEntries) {
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
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: AppColors.divider, width: 2),
              ),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.s3,
              vertical: AppSpacing.s3,
            ),
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
                      onTap: () => shell.onNavigate(e.route),
                      visibleForPapeis: e.visibleForPapeis,
                      currentPapel: shell.papelUsuario,
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
                                  onTap: () => shell.onNavigate(e.route),
                                  visibleForPapeis: e.visibleForPapeis,
                                  currentPapel: shell.papelUsuario,
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
  final AppShell shell;

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
          Icon(LucideIcons.bell, size: 20, color: AppColors.neutral600),
        ],
      ),
    );
  }
}

// ── Mobile ───────────────────────────────────────────────────────────────────

class _MobileShell extends StatelessWidget {
  const _MobileShell({required this.shell});
  final AppShell shell;

  int get _currentBottomIndex {
    for (final e in kNavEntries) {
      if (e.route == shell.currentRoute) return e.bottomNavIndex ?? 0;
    }
    return 0;
  }

  void _onBottomTap(int index, BuildContext context) {
    // Navega para a primeira rota visível do índice selecionado
    final entry = kNavEntries.firstWhere(
      (e) =>
          e.bottomNavIndex == index &&
          (e.visibleForPapeis.isEmpty ||
              e.visibleForPapeis.contains(shell.papelUsuario)),
      orElse: () => kNavEntries.first,
    );
    shell.onNavigate(entry.route);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        shape: const Border(
          bottom: BorderSide(color: AppColors.divider, width: 2),
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
          Icon(LucideIcons.bell, size: 20, color: AppColors.neutral600),
          const SizedBox(width: AppSpacing.s3),
        ],
      ),
      body: shell.child,
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentBottomIndex,
        onTap: (i) => _onBottomTap(i, context),
      ),
    );
  }
}

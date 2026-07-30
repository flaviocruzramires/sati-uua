import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/shell/app_shell.dart';

class PlaceholderScreen extends ConsumerWidget {
  const PlaceholderScreen({super.key, this.route = '/'});

  final String route;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppShell(
      currentRoute: route,
      nomeUsuario: 'Admin SATI',
      papelUsuario: PapelUsuario.admin,
      title: _titleFor(route),
      onNavigate: (_) {},
      onLogout: () {},
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.s8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 8, height: 48, color: AppColors.navy),
              const SizedBox(height: AppSpacing.s4),
              Text('SATI UUA', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: AppSpacing.s2),
              Text(
                'Tela em construção — $_titleFor',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppColors.muted),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _titleFor(String r) => switch (r) {
    '/' => 'Dashboard',
    '/chamados' => 'Chamados',
    '/setores' => 'Setores',
    '/usuarios' => 'Usuários',
    _ => r,
  };
}

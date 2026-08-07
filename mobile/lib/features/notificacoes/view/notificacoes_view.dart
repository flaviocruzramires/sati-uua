import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../../core/auth/current_user_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/actions/app_button.dart';
import '../../../core/widgets/shell/app_shell.dart';
import '../notificacoes_view_model.dart';
import '../notificacao_dto.dart';

final _dtFmt = DateFormat('dd/MM/yyyy HH:mm');

class NotificacoesView extends ConsumerWidget {
  const NotificacoesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final vmState = ref.watch(notificacoesViewModelProvider);
    final vm = ref.read(notificacoesViewModelProvider.notifier);
    final hasUnread =
        vmState.listState.valueOrNull?.any((n) => !n.lida) == true;

    return AppShell(
      currentRoute: '/notificacoes',
      nomeUsuario: user?.nome ?? '',
      papelUsuario: user?.papel,
      title: 'Notificações',
      onNavigate: (r) => context.go(r),
      onLogout: () {},
      actions: [
        if (hasUnread)
          TextButton(
            onPressed: vmState.marking ? null : vm.marcarTodasLidas,
            child: const Text('Marcar todas como lidas'),
          ),
        IconButton(
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          onPressed: vm.load,
          tooltip: 'Atualizar',
        ),
      ],
      child: vmState.listState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Erro ao carregar notificações',
                  style: TextStyle(color: AppColors.muted)),
              const SizedBox(height: AppSpacing.s3),
              AppButton(label: 'Tentar novamente', onPressed: vm.load),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.bell, size: 48, color: AppColors.muted),
                  const SizedBox(height: AppSpacing.s3),
                  Text('Nenhuma notificação',
                      style: TextStyle(color: AppColors.muted)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.s2),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _NotificacaoTile(
              item: items[i],
              onTap: () {
                if (!items[i].lida) vm.marcarLida(items[i].id);
                context.go('/chamados/${items[i].chamadoId}');
              },
            ),
          );
        },
      ),
    );
  }
}

class _NotificacaoTile extends StatelessWidget {
  const _NotificacaoTile({required this.item, required this.onTap});

  final NotificacaoDto item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: item.lida ? null : AppColors.accent100,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s4,
          vertical: AppSpacing.s3,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _iconForTipo(item.tipo),
              size: 18,
              color: item.lida ? AppColors.muted : AppColors.accent500,
            ),
            const SizedBox(width: AppSpacing.s3),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.mensagem,
                    style: TextStyle(
                      fontWeight:
                          item.lida ? FontWeight.normal : FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dtFmt.format(item.criadaEm.toLocal()),
                    style: TextStyle(color: AppColors.muted, fontSize: 11),
                  ),
                ],
              ),
            ),
            if (!item.lida)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconForTipo(String tipo) => switch (tipo) {
    'NOVO_CHAMADO' => LucideIcons.plusCircle,
    'CHAMADO_ASSUMIDO' => LucideIcons.userCheck,
    'RETORNO_ATENDENTE' => LucideIcons.messageSquare,
    'RETORNO_SOLICITANTE' => LucideIcons.messageCircle,
    'CHAMADO_ENCERRADO' => LucideIcons.checkCircle,
    _ => LucideIcons.bell,
  };
}

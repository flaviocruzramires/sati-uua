import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/view/login_view.dart';
import '../../features/equipamentos/view/equipamentos_view.dart';
import '../../features/permissionamento/view/permissionamento_view.dart';
import '../../features/servicos/view/servicos_view.dart';
import '../../features/setores/view/setores_view.dart';
import '../../features/tipos_equipamento/view/tipos_equipamento_view.dart';
import '../../features/chamados/view/abrir_chamado_view.dart';
import '../../features/dashboard/view/dashboard_view.dart';
import '../../features/chamados/view/chamado_detalhe_view.dart';
import '../../features/chamados/view/chamados_list_view.dart';
import '../../features/usuarios/view/usuarios_view.dart';
import '../../features/configuracoes/view/configuracoes_view.dart';
import '../../features/relatorios/view/relatorio_view.dart';
import '../../features/notificacoes/view/notificacoes_view.dart';
import '../auth/permissoes_provider.dart';
import '../network/auth_storage.dart';
import '../widgets/shell/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStorage = ref.read(authStorageProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isAuthenticated = await authStorage.readToken() != null;
      final onLogin = state.matchedLocation == '/login';

      if (!isAuthenticated) return onLogin ? null : '/login';

      // Autenticado: garante que as permissões efetivas já carregaram antes de
      // decidir menu/guarda (rotina 13). Se falhar, segue com permissões vazias
      // (cai na rota de fallback em vez de quebrar a navegação).
      try {
        await ref.read(permissoesProvider.future);
      } catch (_) {}
      final perm = ref.read(permissoesHelperProvider);

      // Pós-login: cai na primeira rota visível (ajuste geral 1) — evita tela
      // negada quando o papel não tem Dashboard.
      if (onLogin) return _primeiraRotaVisivel(perm);

      // Guarda de rota: bloqueia deep-link para tela sem permissão.
      final entry = _entryPorRota(state.matchedLocation);
      if (entry != null && !_visivel(entry, perm)) {
        return _primeiraRotaVisivel(perm);
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginView()),
      GoRoute(path: '/', builder: (_, __) => const DashboardView()),
      GoRoute(path: '/setores', builder: (_, __) => const SetoresView()),
      GoRoute(path: '/servicos', builder: (_, __) => const ServicosView()),
      GoRoute(
        path: '/tipos-equipamento',
        builder: (_, __) => const TiposEquipamentoView(),
      ),
      GoRoute(
        path: '/equipamentos',
        builder: (_, __) => const EquipamentosView(),
      ),
      GoRoute(path: '/usuarios', builder: (_, __) => const UsuariosView()),
      GoRoute(
        path: '/permissionamento',
        builder: (_, __) => const PermissionamentoView(),
      ),
      GoRoute(path: '/chamados', builder: (_, __) => const ChamadosListView()),
      GoRoute(
        path: '/chamados/abrir',
        builder: (_, __) => const AbrirChamadoView(),
      ),
      GoRoute(
        path: '/configuracoes',
        builder: (_, __) => const ConfiguracoesView(),
      ),
      GoRoute(path: '/relatorios', builder: (_, __) => const RelatorioView()),
      GoRoute(
        path: '/notificacoes',
        builder: (_, __) => const NotificacoesView(),
      ),
      GoRoute(
        path: '/chamados/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ChamadoDetalheView(chamadoId: id);
        },
      ),
    ],
  );
});

bool _visivel(NavEntry e, Permissoes perm) => e.adminOnly
    ? perm.isAdmin
    : (e.chave == null || perm.podeVer(e.chave!));

/// Entrada de menu correspondente à rota, ou `null` para rotas fora do menu
/// (login, notificações, sub-rotas de chamado) — essas não são guardadas aqui.
NavEntry? _entryPorRota(String rota) {
  for (final e in kNavEntries) {
    if (e.route == rota) return e;
  }
  return null;
}

String _primeiraRotaVisivel(Permissoes perm) {
  for (final e in kNavEntries) {
    if (_visivel(e, perm)) return e.route;
  }
  return '/notificacoes'; // fallback: sininho é sempre acessível
}

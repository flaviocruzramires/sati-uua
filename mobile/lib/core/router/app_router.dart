import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/view/login_view.dart';
import '../../features/equipamentos/view/equipamentos_view.dart';
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
import '../network/auth_storage.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authStorage = ref.read(authStorageProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) async {
      final isAuthenticated = await authStorage.readToken() != null;
      final onLogin = state.matchedLocation == '/login';

      if (!isAuthenticated && !onLogin) return '/login';
      if (isAuthenticated && onLogin) return '/';
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
        path: '/chamados/:id',
        builder: (_, state) {
          final id = int.parse(state.pathParameters['id']!);
          return ChamadoDetalheView(chamadoId: id);
        },
      ),
    ],
  );
});

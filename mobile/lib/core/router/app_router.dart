import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/view/login_view.dart';
import '../../features/equipamentos/view/equipamentos_view.dart';
import '../../features/placeholder/placeholder_screen.dart';
import '../../features/servicos/view/servicos_view.dart';
import '../../features/setores/view/setores_view.dart';
import '../../features/tipos_equipamento/view/tipos_equipamento_view.dart';
import '../../features/usuarios/view/usuarios_view.dart';
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
      GoRoute(path: '/', builder: (_, __) => const PlaceholderScreen()),
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
      GoRoute(
        path: '/usuarios',
        builder: (_, __) => const UsuariosView(),
      ),
    ],
  );
});

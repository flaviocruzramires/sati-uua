import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/enums.dart';
import '../../features/permissionamento/permissao_repository.dart';
import 'current_user_provider.dart';

/// Permissões efetivas do usuário logado (rotina 13). Carrega `GET /me/permissoes`
/// ao autenticar e recarrega quando o usuário muda (login/logout). Admin recebe
/// tudo liberado do servidor; ainda assim aplicamos bypass local por segurança.
class PermissoesNotifier
    extends AsyncNotifier<Map<String, PermissaoEfetivaDto>> {
  @override
  Future<Map<String, PermissaoEfetivaDto>> build() async {
    final user = await ref.watch(currentUserProvider.future);
    if (user == null) return const {};
    return ref.read(permissaoRepositoryProvider).minhasPermissoes();
  }
}

final permissoesProvider =
    AsyncNotifierProvider<PermissoesNotifier, Map<String, PermissaoEfetivaDto>>(
  PermissoesNotifier.new,
);

/// Fachada síncrona para as telas consultarem permissões por `chave` da rotina.
/// Enquanto carrega, tudo é `false` (nada aparece até saber). Admin → `true`.
class Permissoes {
  const Permissoes(this._map, this.isAdmin);

  final Map<String, PermissaoEfetivaDto> _map;
  final bool isAdmin;

  bool podeVer(String chave) => isAdmin || (_map[chave]?.ver ?? false);
  bool podeIncluir(String chave) => isAdmin || (_map[chave]?.incluir ?? false);
  bool podeAlterar(String chave) => isAdmin || (_map[chave]?.alterar ?? false);
  bool podeExcluir(String chave) => isAdmin || (_map[chave]?.excluir ?? false);
}

final permissoesHelperProvider = Provider<Permissoes>((ref) {
  final map = ref.watch(permissoesProvider).valueOrNull ?? const {};
  final user = ref.watch(currentUserProvider).valueOrNull;
  return Permissoes(map, user?.papel == PapelUsuario.admin);
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/network/api_client.dart';
import 'permissao_dto.dart';

export 'permissao_dto.dart';

abstract class PermissaoRepositoryBase {
  /// Matriz configurável de um papel (`GET /permissoes?papel=`, só Admin).
  Future<List<PermissaoRotinaDto>> matriz(PapelUsuario papel);

  /// Grava o lote e devolve a matriz já normalizada pelo servidor
  /// (`PUT /permissoes?papel=`).
  Future<List<PermissaoRotinaDto>> salvarLote(
    PapelUsuario papel,
    List<PermissaoRotinaDto> itens,
  );

  /// Permissões efetivas do usuário logado (`GET /me/permissoes`), por `chave`.
  Future<Map<String, PermissaoEfetivaDto>> minhasPermissoes();
}

class PermissaoRepository implements PermissaoRepositoryBase {
  const PermissaoRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<PermissaoRotinaDto>> matriz(PapelUsuario papel) async {
    final res = await _client.get<List<dynamic>>(
      '/permissoes',
      queryParameters: {'papel': papel.apiValue},
    );
    return (res.data ?? const [])
        .map((e) => PermissaoRotinaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PermissaoRotinaDto>> salvarLote(
    PapelUsuario papel,
    List<PermissaoRotinaDto> itens,
  ) async {
    final res = await _client.put<List<dynamic>>(
      '/permissoes?papel=${papel.apiValue}',
      data: itens.map((e) => e.toJson()).toList(),
    );
    return (res.data ?? const [])
        .map((e) => PermissaoRotinaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<Map<String, PermissaoEfetivaDto>> minhasPermissoes() async {
    final res = await _client.get<Map<String, dynamic>>('/me/permissoes');
    final body = res.data ?? const <String, dynamic>{};
    return body.map(
      (chave, v) => MapEntry(
        chave,
        PermissaoEfetivaDto.fromJson(v as Map<String, dynamic>),
      ),
    );
  }
}

final permissaoRepositoryProvider = Provider<PermissaoRepositoryBase>((ref) {
  return PermissaoRepository(ref.watch(apiClientProvider));
});

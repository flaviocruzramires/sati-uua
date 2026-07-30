import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/paginated_result.dart';
import '../../core/network/api_client.dart';
import 'usuario_dto.dart';

export 'usuario_dto.dart';

String _papelToStr(PapelUsuario p) => switch (p) {
      PapelUsuario.admin => 'ADMIN',
      PapelUsuario.atendente => 'ATENDENTE',
      PapelUsuario.solicitante => 'SOLICITANTE',
    };

abstract class UsuarioRepositoryBase {
  Future<PaginatedResult<UsuarioDto>> list({
    int page = 1,
    int pageSize = 20,
    PapelUsuario? papel,
  });
  Future<UsuarioDto> create({
    required String nome,
    required String email,
    required String login,
    required String senha,
    required int setorId,
    required PapelUsuario papel,
  });
  Future<UsuarioDto> update({
    required int id,
    required String nome,
    required String email,
    required int setorId,
    required PapelUsuario papel,
    required bool ativo,
    String? senha,
  });
}

class UsuarioRepository implements UsuarioRepositoryBase {
  const UsuarioRepository(this._client);
  final ApiClient _client;

  @override
  Future<PaginatedResult<UsuarioDto>> list({
    int page = 1,
    int pageSize = 20,
    PapelUsuario? papel,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (papel != null) 'papel': _papelToStr(papel),
    };
    final res = await _client.get<Map<String, dynamic>>(
      '/usuarios',
      queryParameters: params,
    );
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List)
        .map((e) => UsuarioDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      total: body['total'] as int,
      page: body['page'] as int,
      pageSize: body['pageSize'] as int,
    );
  }

  @override
  Future<UsuarioDto> create({
    required String nome,
    required String email,
    required String login,
    required String senha,
    required int setorId,
    required PapelUsuario papel,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/usuarios',
      data: {
        'nome': nome,
        'email': email,
        'login': login,
        'senha': senha,
        'setorId': setorId,
        'papel': _papelToStr(papel),
      },
    );
    return UsuarioDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<UsuarioDto> update({
    required int id,
    required String nome,
    required String email,
    required int setorId,
    required PapelUsuario papel,
    required bool ativo,
    String? senha,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/usuarios/$id',
      data: {
        'nome': nome,
        'email': email,
        'setorId': setorId,
        'papel': _papelToStr(papel),
        'ativo': ativo,
        if (senha != null && senha.isNotEmpty) 'senha': senha,
      },
    );
    return UsuarioDto.fromJson(res.data as Map<String, dynamic>);
  }
}

final usuarioRepositoryProvider = Provider<UsuarioRepositoryBase>((ref) {
  return UsuarioRepository(ref.watch(apiClientProvider));
});

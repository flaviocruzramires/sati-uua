import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'notificacao_dto.dart';

export 'notificacao_dto.dart';

abstract class NotificacaoRepositoryBase {
  Future<List<NotificacaoDto>> list();
  Future<int> countNaoLidas();
  Future<void> marcarLida(int id);
  Future<void> marcarTodasLidas();
}

class NotificacaoRepository implements NotificacaoRepositoryBase {
  const NotificacaoRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<NotificacaoDto>> list() async {
    final res = await _client.get<List<dynamic>>('/notificacoes');
    return (res.data as List)
        .map((e) => NotificacaoDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<int> countNaoLidas() async {
    final res = await _client.get<Map<String, dynamic>>('/notificacoes/count');
    final body = res.data as Map<String, dynamic>;
    return body['naoLidas'] as int;
  }

  @override
  Future<void> marcarLida(int id) async {
    await _client.patch<void>('/notificacoes/$id/lida');
  }

  @override
  Future<void> marcarTodasLidas() async {
    await _client.patch<void>('/notificacoes/todas-lidas');
  }
}

final notificacaoRepositoryProvider = Provider<NotificacaoRepositoryBase>((ref) {
  return NotificacaoRepository(ref.watch(apiClientProvider));
});

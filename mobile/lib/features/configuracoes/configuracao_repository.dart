import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'configuracao_dto.dart';

export 'configuracao_dto.dart';

abstract class ConfiguracaoRepositoryBase {
  Future<List<ConfiguracaoDto>> list();
  Future<ConfiguracaoDto> update(String chave, String valor);
}

class ConfiguracaoRepository implements ConfiguracaoRepositoryBase {
  const ConfiguracaoRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<ConfiguracaoDto>> list() async {
    final res = await _client.get<List<dynamic>>('/configuracoes');
    return (res.data as List)
        .map((e) => ConfiguracaoDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<ConfiguracaoDto> update(String chave, String valor) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/configuracoes/$chave',
      data: {'valor': valor},
    );
    return ConfiguracaoDto.fromJson(res.data as Map<String, dynamic>);
  }
}

final configuracaoRepositoryProvider = Provider<ConfiguracaoRepositoryBase>((
  ref,
) {
  return ConfiguracaoRepository(ref.watch(apiClientProvider));
});

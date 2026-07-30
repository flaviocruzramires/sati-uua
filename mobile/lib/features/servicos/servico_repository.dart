import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/paginated_result.dart';
import '../../core/network/api_client.dart';
import 'servico_dto.dart';

export 'servico_dto.dart';

abstract class ServicoRepositoryBase {
  Future<PaginatedResult<ServicoDto>> list({
    int page = 1,
    int pageSize = 20,
    String? busca,
  });
  Future<ServicoDto> create(String descricao);
  Future<ServicoDto> update(int id, String descricao);
  Future<void> delete(int id);
}

class ServicoRepository implements ServicoRepositoryBase {
  const ServicoRepository(this._client);
  final ApiClient _client;

  @override
  Future<PaginatedResult<ServicoDto>> list({
    int page = 1,
    int pageSize = 20,
    String? busca,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (busca != null && busca.isNotEmpty) 'busca': busca,
    };
    final res = await _client.get<Map<String, dynamic>>(
      '/servicos',
      queryParameters: params,
    );
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List)
        .map((e) => ServicoDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      total: body['total'] as int,
      page: body['page'] as int,
      pageSize: body['pageSize'] as int,
    );
  }

  @override
  Future<ServicoDto> create(String descricao) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/servicos',
      data: {'descricao': descricao},
    );
    return ServicoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ServicoDto> update(int id, String descricao) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/servicos/$id',
      data: {'descricao': descricao},
    );
    return ServicoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    await _client.delete<void>('/servicos/$id');
  }
}

final servicoRepositoryProvider = Provider<ServicoRepositoryBase>((ref) {
  return ServicoRepository(ref.watch(apiClientProvider));
});

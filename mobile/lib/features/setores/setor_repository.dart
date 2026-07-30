import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/paginated_result.dart';
import '../../core/network/api_client.dart';
import 'setor_dto.dart';

export 'setor_dto.dart';

abstract class SetorRepositoryBase {
  Future<PaginatedResult<SetorDto>> list({
    int page = 1,
    int pageSize = 20,
    String? busca,
  });
  Future<SetorDto> create(String nome);
  Future<SetorDto> update(int id, String nome);
  Future<void> delete(int id);
}

class SetorRepository implements SetorRepositoryBase {
  const SetorRepository(this._client);
  final ApiClient _client;

  @override
  Future<PaginatedResult<SetorDto>> list({
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
      '/setores',
      queryParameters: params,
    );
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List)
        .map((e) => SetorDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      total: body['total'] as int,
      page: body['page'] as int,
      pageSize: body['pageSize'] as int,
    );
  }

  @override
  Future<SetorDto> create(String nome) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/setores',
      data: {'nome': nome},
    );
    return SetorDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<SetorDto> update(int id, String nome) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/setores/$id',
      data: {'nome': nome},
    );
    return SetorDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    await _client.delete<void>('/setores/$id');
  }
}

final setorRepositoryProvider = Provider<SetorRepositoryBase>((ref) {
  return SetorRepository(ref.watch(apiClientProvider));
});

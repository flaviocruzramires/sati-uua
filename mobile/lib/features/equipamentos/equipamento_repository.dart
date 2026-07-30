import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/paginated_result.dart';
import '../../core/network/api_client.dart';
import 'equipamento_dto.dart';

export 'equipamento_dto.dart';

abstract class EquipamentoRepositoryBase {
  Future<PaginatedResult<EquipamentoDto>> list({
    int page = 1,
    int pageSize = 20,
    int? tipoEquipamentoId,
  });
  Future<EquipamentoDto> create({
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
  });
  Future<EquipamentoDto> update({
    required int id,
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
    required bool ativo,
  });
  Future<void> delete(int id);
}

class EquipamentoRepository implements EquipamentoRepositoryBase {
  const EquipamentoRepository(this._client);
  final ApiClient _client;

  @override
  Future<PaginatedResult<EquipamentoDto>> list({
    int page = 1,
    int pageSize = 20,
    int? tipoEquipamentoId,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (tipoEquipamentoId != null)
        'tipoEquipamentoId': tipoEquipamentoId.toString(),
    };
    final res = await _client.get<Map<String, dynamic>>(
      '/equipamentos',
      queryParameters: params,
    );
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List)
        .map((e) => EquipamentoDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      total: body['total'] as int,
      page: body['page'] as int,
      pageSize: body['pageSize'] as int,
    );
  }

  @override
  Future<EquipamentoDto> create({
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/equipamentos',
      data: {
        'descricao': descricao,
        'tipoEquipamentoId': tipoEquipamentoId,
        if (setorId != null) 'setorId': setorId,
      },
    );
    return EquipamentoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<EquipamentoDto> update({
    required int id,
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
    required bool ativo,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/equipamentos/$id',
      data: {
        'descricao': descricao,
        'tipoEquipamentoId': tipoEquipamentoId,
        'setorId': setorId,
        'ativo': ativo,
      },
    );
    return EquipamentoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    await _client.delete<void>('/equipamentos/$id');
  }
}

final equipamentoRepositoryProvider = Provider<EquipamentoRepositoryBase>((ref) {
  return EquipamentoRepository(ref.watch(apiClientProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/combo_item.dart';
import '../../core/domain/paginated_result.dart';
import '../../core/network/api_client.dart';
import 'tipo_equipamento_dto.dart';

export 'tipo_equipamento_dto.dart';

abstract class TipoEquipamentoRepositoryBase {
  Future<PaginatedResult<TipoEquipamentoDto>> list({
    int page = 1,
    int pageSize = 20,
    String? busca,
  });
  Future<List<ComboItem<int>>> combo();
  Future<TipoEquipamentoDto> create(String nome);
  Future<TipoEquipamentoDto> update(int id, String nome);
  Future<void> delete(int id);
}

class TipoEquipamentoRepository implements TipoEquipamentoRepositoryBase {
  const TipoEquipamentoRepository(this._client);
  final ApiClient _client;

  @override
  Future<PaginatedResult<TipoEquipamentoDto>> list({
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
      '/tipos-equipamento',
      queryParameters: params,
    );
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List)
        .map((e) => TipoEquipamentoDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      total: body['total'] as int,
      page: body['page'] as int,
      pageSize: body['pageSize'] as int,
    );
  }

  @override
  Future<List<ComboItem<int>>> combo() async {
    final res = await _client.get<List<dynamic>>('/tipos-equipamento/combo');
    return (res.data as List)
        .map(
          (e) => ComboItem<int>(
            (e as Map<String, dynamic>)['id'] as int,
            e['nome'] as String,
          ),
        )
        .toList();
  }

  @override
  Future<TipoEquipamentoDto> create(String nome) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/tipos-equipamento',
      data: {'nome': nome},
    );
    return TipoEquipamentoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<TipoEquipamentoDto> update(int id, String nome) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/tipos-equipamento/$id',
      data: {'nome': nome},
    );
    return TipoEquipamentoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<void> delete(int id) async {
    await _client.delete<void>('/tipos-equipamento/$id');
  }
}

final tipoEquipamentoRepositoryProvider =
    Provider<TipoEquipamentoRepositoryBase>((ref) {
      return TipoEquipamentoRepository(ref.watch(apiClientProvider));
    });

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import 'rotina_dto.dart';

export 'rotina_dto.dart';

abstract class RotinaRepositoryBase {
  /// Árvore de rotinas (`GET /rotinas`, restrito a Admin no servidor).
  Future<List<RotinaDto>> listar();
}

class RotinaRepository implements RotinaRepositoryBase {
  const RotinaRepository(this._client);
  final ApiClient _client;

  @override
  Future<List<RotinaDto>> listar() async {
    final res = await _client.get<List<dynamic>>('/rotinas');
    final data = res.data ?? const [];
    return data
        .map((e) => RotinaDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}

final rotinaRepositoryProvider = Provider<RotinaRepositoryBase>((ref) {
  return RotinaRepository(ref.watch(apiClientProvider));
});

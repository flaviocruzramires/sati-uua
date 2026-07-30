import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/network/api_client.dart';
import 'relatorio_dto.dart';

export 'relatorio_dto.dart';

String _situacaoStr(SituacaoChamado s) => switch (s) {
      SituacaoChamado.aberto => 'ABERTO',
      SituacaoChamado.emAndamento => 'EM_ANDAMENTO',
      SituacaoChamado.aguardandoSolicitante => 'AGUARDANDO_SOLICITANTE',
      SituacaoChamado.encerrado => 'ENCERRADO',
    };

abstract class RelatorioRepositoryBase {
  Future<RelatorioResultDto> chamados({
    int page = 1,
    int pageSize = 20,
    SituacaoChamado? situacao,
    int? solicitanteId,
    int? atendenteId,
    int? equipamentoId,
    int? servicoId,
    DateTime? aberturaDe,
    DateTime? aberturaAte,
    DateTime? fechamentoDe,
    DateTime? fechamentoAte,
  });
}

class RelatorioRepository implements RelatorioRepositoryBase {
  const RelatorioRepository(this._client);
  final ApiClient _client;

  @override
  Future<RelatorioResultDto> chamados({
    int page = 1,
    int pageSize = 20,
    SituacaoChamado? situacao,
    int? solicitanteId,
    int? atendenteId,
    int? equipamentoId,
    int? servicoId,
    DateTime? aberturaDe,
    DateTime? aberturaAte,
    DateTime? fechamentoDe,
    DateTime? fechamentoAte,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (situacao != null) 'situacao': _situacaoStr(situacao),
      if (solicitanteId != null) 'solicitanteId': solicitanteId.toString(),
      if (atendenteId != null) 'atendenteId': atendenteId.toString(),
      if (equipamentoId != null) 'equipamentoId': equipamentoId.toString(),
      if (servicoId != null) 'servicoId': servicoId.toString(),
      if (aberturaDe != null)
        'aberturaDe': aberturaDe.toUtc().toIso8601String(),
      if (aberturaAte != null)
        'aberturaAte': aberturaAte.toUtc().toIso8601String(),
      if (fechamentoDe != null)
        'fechamentoDe': fechamentoDe.toUtc().toIso8601String(),
      if (fechamentoAte != null)
        'fechamentoAte': fechamentoAte.toUtc().toIso8601String(),
    };
    final res = await _client.get<Map<String, dynamic>>(
      '/relatorios/chamados',
      queryParameters: params,
    );
    return RelatorioResultDto.fromJson(res.data as Map<String, dynamic>);
  }
}

final relatorioRepositoryProvider =
    Provider<RelatorioRepositoryBase>((ref) {
  return RelatorioRepository(ref.watch(apiClientProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/domain/enums.dart';
import '../../core/domain/paginated_result.dart';
import '../../core/network/api_client.dart';
import 'chamado_detalhe_dto.dart';
import 'chamado_dto.dart';

export 'chamado_detalhe_dto.dart';
export 'chamado_dto.dart';

String _dateToStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _situacaoToStr(SituacaoChamado s) => switch (s) {
  SituacaoChamado.aberto => 'ABERTO',
  SituacaoChamado.emAndamento => 'EM_ANDAMENTO',
  SituacaoChamado.aguardandoSolicitante => 'AGUARDANDO_SOLICITANTE',
  SituacaoChamado.encerrado => 'ENCERRADO',
};

abstract class ChamadoRepositoryBase {
  Future<PaginatedResult<ChamadoDto>> list({
    int page = 1,
    int pageSize = 20,
    SituacaoChamado? situacao,
    int? solicitanteId,
    int? responsavelId,
    DateTime? dataAberturaInicio,
    DateTime? dataAberturaFim,
  });

  Future<ChamadoDto> findById(int id);

  Future<ChamadoDetalheDto> findDetalhe(int id);

  Future<ChamadoDetalheDto> registrarHistorico({
    required int chamadoId,
    required String descricao,
    required DateTime dataRetorno,
    required bool marcaEncerramento,
    DateTime? dataPrevistaRetorno,
  });

  Future<ChamadoDto> create({
    required String descricao,
    int? equipamentoId,
    int? servicoId,
  });

  Future<ChamadoDto> atribuirResponsavel({
    required int id,
    required int responsavelId,
  });

  Future<ChamadoDto> atualizarTerceiro({
    required int id,
    required bool envolveTerceiro,
    String? nomeTerceiro,
  });

  Future<ChamadoDetalheDto> enviarRetornoSolicitante({
    required int chamadoId,
    required String descricao,
    required DateTime dataRetorno,
  });
}

class ChamadoRepository implements ChamadoRepositoryBase {
  const ChamadoRepository(this._client);
  final ApiClient _client;

  @override
  Future<PaginatedResult<ChamadoDto>> list({
    int page = 1,
    int pageSize = 20,
    SituacaoChamado? situacao,
    int? solicitanteId,
    int? responsavelId,
    DateTime? dataAberturaInicio,
    DateTime? dataAberturaFim,
  }) async {
    final params = <String, dynamic>{
      'page': page.toString(),
      'pageSize': pageSize.toString(),
      if (situacao != null) 'situacao': _situacaoToStr(situacao),
      if (solicitanteId != null) 'solicitanteId': solicitanteId.toString(),
      if (responsavelId != null) 'responsavelId': responsavelId.toString(),
      if (dataAberturaInicio != null)
        'dataAberturaInicio': _dateToStr(dataAberturaInicio),
      if (dataAberturaFim != null)
        'dataAberturaFim': _dateToStr(dataAberturaFim),
    };
    final res = await _client.get<Map<String, dynamic>>(
      '/chamados',
      queryParameters: params,
    );
    final body = res.data as Map<String, dynamic>;
    final data = (body['data'] as List)
        .map((e) => ChamadoDto.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResult(
      data: data,
      total: body['total'] as int,
      page: body['page'] as int,
      pageSize: body['pageSize'] as int,
    );
  }

  @override
  Future<ChamadoDto> findById(int id) async {
    final res = await _client.get<Map<String, dynamic>>('/chamados/$id');
    return ChamadoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ChamadoDetalheDto> findDetalhe(int id) async {
    final res = await _client.get<Map<String, dynamic>>('/chamados/$id');
    return ChamadoDetalheDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ChamadoDetalheDto> registrarHistorico({
    required int chamadoId,
    required String descricao,
    required DateTime dataRetorno,
    required bool marcaEncerramento,
    DateTime? dataPrevistaRetorno,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/chamados/$chamadoId/historico',
      data: {
        'descricao': descricao,
        'dataRetorno': dataRetorno.toUtc().toIso8601String(),
        'marcaEncerramento': marcaEncerramento,
        if (dataPrevistaRetorno != null)
          'dataPrevistaRetorno':
              '${dataPrevistaRetorno.year}-${dataPrevistaRetorno.month.toString().padLeft(2, '0')}-${dataPrevistaRetorno.day.toString().padLeft(2, '0')}',
      },
    );
    return ChamadoDetalheDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ChamadoDto> create({
    required String descricao,
    int? equipamentoId,
    int? servicoId,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/chamados',
      data: {
        'descricao': descricao,
        if (equipamentoId != null) 'equipamentoId': equipamentoId,
        if (servicoId != null) 'servicoId': servicoId,
      },
    );
    return ChamadoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ChamadoDto> atribuirResponsavel({
    required int id,
    required int responsavelId,
  }) async {
    final res = await _client.put<Map<String, dynamic>>(
      '/chamados/$id',
      data: {'responsavelId': responsavelId},
    );
    return ChamadoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ChamadoDto> atualizarTerceiro({
    required int id,
    required bool envolveTerceiro,
    String? nomeTerceiro,
  }) async {
    final res = await _client.patch<Map<String, dynamic>>(
      '/chamados/$id/terceiro',
      data: {
        'envolveTerceiro': envolveTerceiro,
        if (nomeTerceiro != null) 'nomeTerceiro': nomeTerceiro,
      },
    );
    return ChamadoDto.fromJson(res.data as Map<String, dynamic>);
  }

  @override
  Future<ChamadoDetalheDto> enviarRetornoSolicitante({
    required int chamadoId,
    required String descricao,
    required DateTime dataRetorno,
  }) async {
    final res = await _client.post<Map<String, dynamic>>(
      '/chamados/$chamadoId/retorno-solicitante',
      data: {
        'descricao': descricao,
        'dataRetorno': dataRetorno.toUtc().toIso8601String(),
      },
    );
    return ChamadoDetalheDto.fromJson(res.data as Map<String, dynamic>);
  }
}

final chamadoRepositoryProvider = Provider<ChamadoRepositoryBase>((ref) {
  return ChamadoRepository(ref.watch(apiClientProvider));
});

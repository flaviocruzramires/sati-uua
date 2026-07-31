import 'dart:convert';

import 'package:postgres/postgres.dart';

String _pgEnum(Object? value) {
  if (value is String) return value;
  if (value is UndecodedBytes) return utf8.decode(value.bytes);
  return value.toString();
}

class RelatorioResumo {
  const RelatorioResumo({
    required this.total,
    required this.abertos,
    required this.emAndamento,
    required this.aguardandoSolicitante,
    required this.encerrados,
    required this.tempoMedioMinutos,
  });

  final int total;
  final int abertos;
  final int emAndamento;
  final int aguardandoSolicitante;
  final int encerrados;
  final double tempoMedioMinutos;

  Map<String, dynamic> toJson() => {
        'total': total,
        'abertos': abertos,
        'emAndamento': emAndamento,
        'aguardandoSolicitante': aguardandoSolicitante,
        'encerrados': encerrados,
        'tempoMedioMinutos': tempoMedioMinutos,
      };
}

class RelatorioItem {
  const RelatorioItem({
    required this.id,
    required this.situacao,
    required this.dataAbertura,
    this.dataFechamento,
    required this.solicitanteNome,
    required this.solicitanteSetor,
    this.responsavelNome,
    this.equipamentoDescricao,
    this.tipoEquipamentoNome,
    this.servicoDescricao,
  });

  final int id;
  final String situacao;
  final DateTime dataAbertura;
  final DateTime? dataFechamento;
  final String solicitanteNome;
  final String solicitanteSetor;
  final String? responsavelNome;
  final String? equipamentoDescricao;
  final String? tipoEquipamentoNome;
  final String? servicoDescricao;

  Map<String, dynamic> toJson() => {
        'id': id,
        'situacao': situacao,
        'dataAbertura': dataAbertura.toIso8601String(),
        'dataFechamento': dataFechamento?.toIso8601String(),
        'solicitanteNome': solicitanteNome,
        'solicitanteSetor': solicitanteSetor,
        'responsavelNome': responsavelNome,
        'equipamentoDescricao': equipamentoDescricao,
        'tipoEquipamentoNome': tipoEquipamentoNome,
        'servicoDescricao': servicoDescricao,
      };
}

class RelatorioResult {
  const RelatorioResult({
    required this.data,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.resumo,
  });

  final List<RelatorioItem> data;
  final int total;
  final int page;
  final int pageSize;
  final RelatorioResumo resumo;

  Map<String, dynamic> toJson() => {
        'data': data.map((e) => e.toJson()).toList(),
        'total': total,
        'page': page,
        'pageSize': pageSize,
        'resumo': resumo.toJson(),
      };
}

class RelatorioRepository {
  const RelatorioRepository(this._db);
  final Connection _db;

  Future<RelatorioResult> chamados({
    int page = 1,
    int pageSize = 20,
    String? situacao,
    int? solicitanteId,
    int? atendenteId,
    int? equipamentoId,
    int? servicoId,
    DateTime? aberturaDe,
    DateTime? aberturaAte,
    DateTime? fechamentoDe,
    DateTime? fechamentoAte,
  }) async {
    final conditions = <String>[];
    final params = <String, dynamic>{};

    if (situacao != null) {
      conditions.add('v.situacao = @situacao::situacao_chamado');
      params['situacao'] = situacao;
    }
    if (solicitanteId != null) {
      conditions.add('v.usuario_solicitante_id = @solicitanteId');
      params['solicitanteId'] = solicitanteId;
    }
    if (atendenteId != null) {
      conditions.add('v.usuario_responsavel_id = @atendenteId');
      params['atendenteId'] = atendenteId;
    }
    if (equipamentoId != null) {
      conditions.add('v.equipamento_id = @equipamentoId');
      params['equipamentoId'] = equipamentoId;
    }
    if (servicoId != null) {
      conditions.add('v.servico_id = @servicoId');
      params['servicoId'] = servicoId;
    }
    if (aberturaDe != null) {
      conditions.add('v.data_abertura >= @aberturaDe');
      params['aberturaDe'] = aberturaDe.toUtc();
    }
    if (aberturaAte != null) {
      conditions.add('v.data_abertura <= @aberturaAte');
      params['aberturaAte'] = aberturaAte.toUtc();
    }
    if (fechamentoDe != null) {
      conditions.add('v.data_fechamento >= @fechamentoDe');
      params['fechamentoDe'] = fechamentoDe.toUtc();
    }
    if (fechamentoAte != null) {
      conditions.add('v.data_fechamento <= @fechamentoAte');
      params['fechamentoAte'] = fechamentoAte.toUtc();
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';
    final offset = (page - 1) * pageSize;

    // resumo calculado sobre o conjunto filtrado completo (não sobre a página)
    final resumoRows = await _db.execute(
      Sql.named(
        "SELECT COUNT(*), "
        "  COUNT(*) FILTER (WHERE v.situacao = 'ABERTO'), "
        "  COUNT(*) FILTER (WHERE v.situacao = 'EM_ANDAMENTO'), "
        "  COUNT(*) FILTER (WHERE v.situacao = 'AGUARDANDO_SOLICITANTE'), "
        "  COUNT(*) FILTER (WHERE v.situacao = 'ENCERRADO'), "
        '  COALESCE(AVG(EXTRACT(EPOCH FROM (v.data_fechamento - v.data_abertura)) / 60) '
        "    FILTER (WHERE v.situacao = 'ENCERRADO'), 0) "
        'FROM vw_chamados_relatorio v $where',
      ),
      parameters: params,
    );
    final rr = resumoRows.first;
    final resumo = RelatorioResumo(
      total: (rr[0] as int?) ?? 0,
      abertos: (rr[1] as int?) ?? 0,
      emAndamento: (rr[2] as int?) ?? 0,
      aguardandoSolicitante: (rr[3] as int?) ?? 0,
      encerrados: (rr[4] as int?) ?? 0,
      tempoMedioMinutos: (rr[5] as num?)?.toDouble() ?? 0.0,
    );

    final dataRows = await _db.execute(
      Sql.named(
        'SELECT v.id, v.situacao, v.data_abertura, v.data_fechamento, '
        '       v.solicitante_nome, s.nome AS setor_nome, '
        '       v.responsavel_nome, v.equipamento_descricao, '
        '       v.tipo_equipamento_nome, v.servico_descricao '
        'FROM vw_chamados_relatorio v '
        'LEFT JOIN setores s ON s.id = v.solicitante_setor_id '
        '$where '
        'ORDER BY v.data_abertura DESC '
        'LIMIT @limit OFFSET @offset',
      ),
      parameters: {...params, 'limit': pageSize, 'offset': offset},
    );

    final data = dataRows.map(_fromRow).toList();

    return RelatorioResult(
      data: data,
      total: resumo.total,
      page: page,
      pageSize: pageSize,
      resumo: resumo,
    );
  }

  RelatorioItem _fromRow(ResultRow row) => RelatorioItem(
        id: row[0] as int,
        situacao: _pgEnum(row[1]),
        dataAbertura: row[2] as DateTime,
        dataFechamento: row[3] as DateTime?,
        solicitanteNome: row[4] as String,
        solicitanteSetor: (row[5] as String?) ?? '—',
        responsavelNome: row[6] as String?,
        equipamentoDescricao: row[7] as String?,
        tipoEquipamentoNome: row[8] as String?,
        servicoDescricao: row[9] as String?,
      );
}

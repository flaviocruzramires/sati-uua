import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../models/chamado.dart';

String _pgEnum(Object? value) {
  if (value is String) return value;
  if (value is UndecodedBytes) return utf8.decode(value.bytes);
  return value.toString();
}

class ChamadoRepository {
  const ChamadoRepository(this._db);
  final Connection _db;

  static const _selectCols = '''
    c.id,
    c.descricao,
    c.usuario_solicitante_id,
    us.nome AS solicitante_nome,
    st.nome AS solicitante_setor_nome,
    c.usuario_responsavel_id,
    ur.nome AS responsavel_nome,
    c.equipamento_id,
    e.descricao AS equipamento_descricao,
    c.servico_id,
    s.descricao AS servico_nome,
    c.situacao,
    c.data_abertura,
    c.data_fechamento
  ''';

  static const _joins = '''
    FROM chamados c
    JOIN usuarios us ON us.id = c.usuario_solicitante_id
    LEFT JOIN setores st ON st.id = us.setor_id
    LEFT JOIN usuarios ur ON ur.id = c.usuario_responsavel_id
    LEFT JOIN equipamentos e ON e.id = c.equipamento_id
    LEFT JOIN servicos s ON s.id = c.servico_id
  ''';

  Future<({List<Chamado> data, int total})> list({
    int page = 1,
    int pageSize = 20,
    String? situacao,
    int? solicitanteId,
    int? responsavelId,
    DateTime? dataAberturaInicio,
    DateTime? dataAberturaFim,
  }) async {
    final offset = (page - 1) * pageSize;
    final conditions = <String>[];
    final params = <String, dynamic>{};

    if (situacao != null) {
      conditions.add("c.situacao = @situacao::situacao_chamado");
      params['situacao'] = situacao;
    }
    if (solicitanteId != null) {
      conditions.add("c.usuario_solicitante_id = @solicitanteId");
      params['solicitanteId'] = solicitanteId;
    }
    if (responsavelId != null) {
      conditions.add("c.usuario_responsavel_id = @responsavelId");
      params['responsavelId'] = responsavelId;
    }
    if (dataAberturaInicio != null) {
      conditions.add("c.data_abertura >= @dataAberturaInicio");
      params['dataAberturaInicio'] = dataAberturaInicio;
    }
    if (dataAberturaFim != null) {
      conditions.add("c.data_abertura < @dataAberturaFim");
      params['dataAberturaFim'] = dataAberturaFim;
    }

    final where = conditions.isEmpty ? '' : 'WHERE ${conditions.join(' AND ')}';

    final countResult = await _db.execute(
      Sql.named('SELECT COUNT(*) FROM chamados c $where'),
      parameters: params,
    );
    final total = countResult.first[0] as int;

    final rows = await _db.execute(
      Sql.named(
        'SELECT $_selectCols $_joins $where '
        'ORDER BY c.data_abertura DESC LIMIT @limit OFFSET @offset',
      ),
      parameters: {...params, 'limit': pageSize, 'offset': offset},
    );

    return (data: rows.map(_fromRow).toList(), total: total);
  }

  Chamado _fromRow(ResultRow row) => Chamado(
        id: row[0] as int,
        descricao: row[1] as String,
        solicitanteId: row[2] as int,
        solicitanteNome: row[3] as String,
        solicitanteSetorNome: row[4] as String?,
        responsavelId: row[5] as int?,
        responsavelNome: row[6] as String?,
        equipamentoId: row[7] as int?,
        equipamentoDescricao: row[8] as String?,
        servicoId: row[9] as int?,
        servicoNome: row[10] as String?,
        situacao: _pgEnum(row[11]),
        dataAbertura: row[12] as DateTime,
        dataFechamento: row[13] as DateTime?,
      );

  Future<Chamado?> findById(int id) async {
    final rows = await _db.execute(
      Sql.named('SELECT $_selectCols $_joins WHERE c.id = @id'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<Chamado> create({
    required String descricao,
    required int solicitanteId,
    int? equipamentoId,
    int? servicoId,
  }) async {
    final result = await _db.execute(
      Sql.named(
        'INSERT INTO chamados (descricao, usuario_solicitante_id, equipamento_id, servico_id) '
        'VALUES (@descricao, @solicitanteId, @equipamentoId, @servicoId) '
        'RETURNING id',
      ),
      parameters: {
        'descricao': descricao,
        'solicitanteId': solicitanteId,
        'equipamentoId': equipamentoId,
        'servicoId': servicoId,
      },
    );
    final newId = result.first[0] as int;
    return (await findById(newId))!;
  }

  Future<Chamado?> atribuirResponsavel({
    required int id,
    required int responsavelId,
  }) async {
    await _db.execute(
      Sql.named(
        "UPDATE chamados SET usuario_responsavel_id = @responsavelId, "
        "  situacao = 'EM_ANDAMENTO'::situacao_chamado "
        'WHERE id = @id',
      ),
      parameters: {'id': id, 'responsavelId': responsavelId},
    );
    return findById(id);
  }
}

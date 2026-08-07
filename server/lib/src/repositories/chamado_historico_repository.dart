import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../models/chamado.dart';
import '../models/chamado_detalhe.dart';
import '../models/chamado_historico.dart';

String _pgEnum(Object? value) {
  if (value is String) return value;
  if (value is UndecodedBytes) return utf8.decode(value.bytes);
  return value.toString();
}

class ChamadoHistoricoRepository {
  const ChamadoHistoricoRepository(this._db);
  final Connection _db;

  Future<List<ChamadoHistorico>> listByChamado(int chamadoId) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT h.id, h.chamado_id, h.usuario_responsavel_id, ur.nome, '
        '       h.usuario_solicitante_id, us.nome, '
        '       h.data_retorno, h.descricao, h.marca_encerramento, '
        '       h.tipo_registro, h.data_prevista_retorno '
        'FROM chamado_historico h '
        'LEFT JOIN usuarios ur ON ur.id = h.usuario_responsavel_id '
        'LEFT JOIN usuarios us ON us.id = h.usuario_solicitante_id '
        'WHERE h.chamado_id = @chamadoId '
        'ORDER BY h.data_retorno ASC',
      ),
      parameters: {'chamadoId': chamadoId},
    );
    return rows.map(_fromRow).toList();
  }

  /// Registro do atendente. Se marca_encerramento=true, encerra o chamado.
  Future<ChamadoDetalhe> registrar({
    required int chamadoId,
    required int responsavelId,
    required DateTime dataRetorno,
    required String descricao,
    required bool marcaEncerramento,
    DateTime? dataPrevistaRetorno,
  }) async {
    final check = await _db.execute(
      Sql.named('SELECT usuario_responsavel_id FROM chamados WHERE id = @id'),
      parameters: {'id': chamadoId},
    );
    if (check.isEmpty) throw StateError('Chamado não encontrado');
    if (check.first[0] == null) {
      throw StateError(
          'Chamado sem atendente atribuído não pode receber registro');
    }

    late Chamado chamado;

    await _db.runTx((tx) async {
      await tx.execute(
        Sql.named(
          'INSERT INTO chamado_historico '
          '  (chamado_id, usuario_responsavel_id, data_retorno, descricao, '
          '   marca_encerramento, tipo_registro, data_prevista_retorno) '
          'VALUES (@chamadoId, @responsavelId, @dataRetorno, @descricao, '
          '        @marcaEncerramento, \'ATENDIMENTO\', @dataPrevistaRetorno)',
        ),
        parameters: {
          'chamadoId': chamadoId,
          'responsavelId': responsavelId,
          'dataRetorno': dataRetorno.toUtc(),
          'descricao': descricao,
          'marcaEncerramento': marcaEncerramento,
          'dataPrevistaRetorno': dataPrevistaRetorno,
        },
      );

      if (marcaEncerramento) {
        await tx.execute(
          Sql.named(
            "UPDATE chamados "
            "SET situacao = 'ENCERRADO'::situacao_chamado, data_fechamento = now() "
            'WHERE id = @chamadoId',
          ),
          parameters: {'chamadoId': chamadoId},
        );
      }

      final cRows = await tx.execute(
        Sql.named(_chamadoSelectSql),
        parameters: {'id': chamadoId},
      );
      chamado = _chamadoFromRow(cRows.first);
    });

    final allHistorico = await listByChamado(chamadoId);
    return ChamadoDetalhe(chamado: chamado, historico: allHistorico);
  }

  /// Retorno do solicitante — não encerra, não requer atendente atribuído.
  Future<ChamadoDetalhe> registrarRetornoSolicitante({
    required int chamadoId,
    required int solicitanteId,
    required String descricao,
  }) async {
    final check = await _db.execute(
      Sql.named(
        'SELECT usuario_solicitante_id, situacao FROM chamados WHERE id = @id',
      ),
      parameters: {'id': chamadoId},
    );
    if (check.isEmpty) throw StateError('Chamado não encontrado');
    if (check.first[0] as int != solicitanteId) {
      throw StateError('Apenas o solicitante do chamado pode enviar retorno');
    }
    final situacao = _pgEnum(check.first[1]);
    if (situacao == 'ENCERRADO') {
      throw StateError('Chamado encerrado não aceita mais atualizações');
    }

    await _db.execute(
      Sql.named(
        'INSERT INTO chamado_historico '
        '  (chamado_id, usuario_solicitante_id, data_retorno, descricao, '
        '   marca_encerramento, tipo_registro) '
        'VALUES (@chamadoId, @solicitanteId, now(), @descricao, false, '
        '        \'RETORNO_SOLICITANTE\')',
      ),
      parameters: {
        'chamadoId': chamadoId,
        'solicitanteId': solicitanteId,
        'descricao': descricao,
      },
    );

    final cRows = await _db.execute(
      Sql.named(_chamadoSelectSql),
      parameters: {'id': chamadoId},
    );
    final chamado = _chamadoFromRow(cRows.first);
    final allHistorico = await listByChamado(chamadoId);
    return ChamadoDetalhe(chamado: chamado, historico: allHistorico);
  }

  ChamadoHistorico _fromRow(ResultRow row) => ChamadoHistorico(
        id: row[0] as int,
        chamadoId: row[1] as int,
        responsavelId: row[2] as int?,
        responsavelNome: row[3] as String?,
        solicitanteId: row[4] as int?,
        solicitanteNome: row[5] as String?,
        dataRetorno: row[6] as DateTime,
        descricao: row[7] as String,
        marcaEncerramento: row[8] as bool,
        tipoRegistro: row[9] as String? ?? 'ATENDIMENTO',
        dataPrevistaRetorno: row[10] as DateTime?,
      );

  static const _chamadoSelectSql =
      'SELECT c.id, c.descricao, c.usuario_solicitante_id, us.nome, '
      '       st.nome, c.usuario_responsavel_id, ur.nome, '
      '       c.equipamento_id, e.descricao, c.servico_id, s.descricao, '
      '       c.situacao, c.data_abertura, c.data_fechamento, '
      '       c.envolve_terceiro, c.nome_terceiro '
      'FROM chamados c '
      'JOIN usuarios us ON us.id = c.usuario_solicitante_id '
      'LEFT JOIN setores st ON st.id = us.setor_id '
      'LEFT JOIN usuarios ur ON ur.id = c.usuario_responsavel_id '
      'LEFT JOIN equipamentos e ON e.id = c.equipamento_id '
      'LEFT JOIN servicos s ON s.id = c.servico_id '
      'WHERE c.id = @id';

  Chamado _chamadoFromRow(ResultRow row) => Chamado(
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
        envolveTerceiro: (row[14] as bool?) ?? false,
        nomeTerceiro: row[15] as String?,
      );
}

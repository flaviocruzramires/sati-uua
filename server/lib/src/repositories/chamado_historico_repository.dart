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
        'SELECT h.id, h.chamado_id, h.usuario_responsavel_id, u.nome, '
        '       h.data_retorno, h.descricao, h.marca_encerramento '
        'FROM chamado_historico h '
        'JOIN usuarios u ON u.id = h.usuario_responsavel_id '
        'WHERE h.chamado_id = @chamadoId '
        'ORDER BY h.data_retorno ASC',
      ),
      parameters: {'chamadoId': chamadoId},
    );
    return rows.map(_fromRow).toList();
  }

  /// Cria registro. Se marca_encerramento=true, encerra o chamado na mesma transação.
  /// Lança StateError se chamado não tem responsável.
  Future<ChamadoDetalhe> registrar({
    required int chamadoId,
    required int responsavelId,
    required DateTime dataRetorno,
    required String descricao,
    required bool marcaEncerramento,
  }) async {
    // Verificar responsável antes de abrir transação
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
          '  (chamado_id, usuario_responsavel_id, data_retorno, descricao, marca_encerramento) '
          'VALUES (@chamadoId, @responsavelId, @dataRetorno, @descricao, @marcaEncerramento)',
        ),
        parameters: {
          'chamadoId': chamadoId,
          'responsavelId': responsavelId,
          'dataRetorno': dataRetorno.toUtc(),
          'descricao': descricao,
          'marcaEncerramento': marcaEncerramento,
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

      // Carregar chamado atualizado (dentro da tx)
      final cRows = await tx.execute(
        Sql.named(
          'SELECT c.id, c.descricao, c.usuario_solicitante_id, us.nome, '
          '       c.usuario_responsavel_id, ur.nome, '
          '       c.equipamento_id, e.descricao, c.servico_id, s.nome, '
          '       c.situacao, c.data_abertura, c.data_fechamento '
          'FROM chamados c '
          'JOIN usuarios us ON us.id = c.usuario_solicitante_id '
          'LEFT JOIN usuarios ur ON ur.id = c.usuario_responsavel_id '
          'LEFT JOIN equipamentos e ON e.id = c.equipamento_id '
          'LEFT JOIN servicos s ON s.id = c.servico_id '
          'WHERE c.id = @id',
        ),
        parameters: {'id': chamadoId},
      );
      chamado = _chamadoFromRow(cRows.first);
    });

    final allHistorico = await listByChamado(chamadoId);
    return ChamadoDetalhe(chamado: chamado, historico: allHistorico);
  }

  ChamadoHistorico _fromRow(ResultRow row) => ChamadoHistorico(
        id: row[0] as int,
        chamadoId: row[1] as int,
        responsavelId: row[2] as int,
        responsavelNome: row[3] as String,
        dataRetorno: row[4] as DateTime,
        descricao: row[5] as String,
        marcaEncerramento: row[6] as bool,
      );

  Chamado _chamadoFromRow(ResultRow row) => Chamado(
        id: row[0] as int,
        descricao: row[1] as String,
        solicitanteId: row[2] as int,
        solicitanteNome: row[3] as String,
        responsavelId: row[4] as int?,
        responsavelNome: row[5] as String?,
        equipamentoId: row[6] as int?,
        equipamentoDescricao: row[7] as String?,
        servicoId: row[8] as int?,
        servicoNome: row[9] as String?,
        situacao: _pgEnum(row[10]),
        dataAbertura: row[11] as DateTime,
        dataFechamento: row[12] as DateTime?,
      );
}

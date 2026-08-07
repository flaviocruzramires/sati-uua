import 'package:postgres/postgres.dart';

import '../models/notificacao.dart';

class NotificacaoRepository {
  const NotificacaoRepository(this._db);
  final Connection _db;

  Future<void> criar({
    required List<int> usuarioIds,
    required int chamadoId,
    required String tipo,
    required String mensagem,
  }) async {
    if (usuarioIds.isEmpty) return;
    for (final uid in usuarioIds) {
      await _db.execute(
        Sql.named(
          'INSERT INTO notificacoes (usuario_id, chamado_id, tipo, mensagem) '
          'VALUES (@usuarioId, @chamadoId, @tipo, @mensagem)',
        ),
        parameters: {
          'usuarioId': uid,
          'chamadoId': chamadoId,
          'tipo': tipo,
          'mensagem': mensagem,
        },
      );
    }
  }

  Future<List<Notificacao>> listByUsuario(int usuarioId) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT id, usuario_id, chamado_id, tipo, mensagem, lida, criada_em '
        'FROM notificacoes WHERE usuario_id = @usuarioId '
        'ORDER BY lida ASC, criada_em DESC LIMIT 50',
      ),
      parameters: {'usuarioId': usuarioId},
    );
    return rows.map(_fromRow).toList();
  }

  Future<int> countNaoLidas(int usuarioId) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT COUNT(*) FROM notificacoes '
        'WHERE usuario_id = @usuarioId AND lida = false',
      ),
      parameters: {'usuarioId': usuarioId},
    );
    return rows.first[0] as int;
  }

  Future<void> marcarLida(int id, int usuarioId) async {
    await _db.execute(
      Sql.named(
        'UPDATE notificacoes SET lida = true '
        'WHERE id = @id AND usuario_id = @usuarioId',
      ),
      parameters: {'id': id, 'usuarioId': usuarioId},
    );
  }

  Future<void> marcarTodasLidas(int usuarioId) async {
    await _db.execute(
      Sql.named(
        'UPDATE notificacoes SET lida = true WHERE usuario_id = @usuarioId',
      ),
      parameters: {'usuarioId': usuarioId},
    );
  }

  Notificacao _fromRow(ResultRow row) => Notificacao(
        id: row[0] as int,
        usuarioId: row[1] as int,
        chamadoId: row[2] as int,
        tipo: row[3] as String,
        mensagem: row[4] as String,
        lida: row[5] as bool,
        criadaEm: row[6] as DateTime,
      );
}

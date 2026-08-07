import 'package:postgres/postgres.dart';

import '../models/anexo.dart';

class AnexoRepository {
  const AnexoRepository(this._db);
  final Connection _db;

  Future<Anexo> criar({
    required int chamadoId,
    int? historicoId,
    required int usuarioId,
    required String nomeArquivo,
    required int tamanhoBytes,
    required String mimeType,
    required String caminho,
  }) async {
    final rows = await _db.execute(
      Sql.named(
        'INSERT INTO chamado_anexos '
        '  (chamado_id, historico_id, usuario_id, nome_arquivo, tamanho_bytes, mime_type, caminho) '
        'VALUES (@chamadoId, @historicoId, @usuarioId, @nomeArquivo, @tamanhoBytes, @mimeType, @caminho) '
        'RETURNING id, token, criado_em',
      ),
      parameters: {
        'chamadoId': chamadoId,
        'historicoId': historicoId,
        'usuarioId': usuarioId,
        'nomeArquivo': nomeArquivo,
        'tamanhoBytes': tamanhoBytes,
        'mimeType': mimeType,
        'caminho': caminho,
      },
    );
    final row = rows.first;
    final usuarioNome = await _nomeUsuario(usuarioId);
    return Anexo(
      id: row[0] as int,
      token: (row[1] as Object).toString(),
      chamadoId: chamadoId,
      historicoId: historicoId,
      usuarioId: usuarioId,
      usuarioNome: usuarioNome,
      nomeArquivo: nomeArquivo,
      tamanhoBytes: tamanhoBytes,
      mimeType: mimeType,
      caminho: caminho,
      criadoEm: row[2] as DateTime,
    );
  }

  Future<List<Anexo>> listByChamado(int chamadoId) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT a.id, a.token, a.chamado_id, a.historico_id, a.usuario_id, u.nome, '
        '       a.nome_arquivo, a.tamanho_bytes, a.mime_type, a.caminho, a.criado_em '
        'FROM chamado_anexos a '
        'JOIN usuarios u ON u.id = a.usuario_id '
        'WHERE a.chamado_id = @chamadoId '
        'ORDER BY a.criado_em ASC',
      ),
      parameters: {'chamadoId': chamadoId},
    );
    return rows.map(_fromRow).toList();
  }

  Future<Anexo?> findById(int id) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT a.id, a.token, a.chamado_id, a.historico_id, a.usuario_id, u.nome, '
        '       a.nome_arquivo, a.tamanho_bytes, a.mime_type, a.caminho, a.criado_em '
        'FROM chamado_anexos a '
        'JOIN usuarios u ON u.id = a.usuario_id '
        'WHERE a.id = @id',
      ),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  /// Busca pelo token público (UUID) usado na URL de download.
  Future<Anexo?> findByToken(String token) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT a.id, a.token, a.chamado_id, a.historico_id, a.usuario_id, u.nome, '
        '       a.nome_arquivo, a.tamanho_bytes, a.mime_type, a.caminho, a.criado_em '
        'FROM chamado_anexos a '
        'JOIN usuarios u ON u.id = a.usuario_id '
        'WHERE a.token = @token',
      ),
      parameters: {'token': token},
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> deletar(int id) async {
    await _db.execute(
      Sql.named('DELETE FROM chamado_anexos WHERE id = @id'),
      parameters: {'id': id},
    );
  }

  Future<String> _nomeUsuario(int id) async {
    final rows = await _db.execute(
      Sql.named('SELECT nome FROM usuarios WHERE id = @id'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return '';
    return rows.first[0] as String;
  }

  static Anexo _fromRow(ResultRow row) => Anexo(
        id: row[0] as int,
        token: (row[1] as Object).toString(),
        chamadoId: row[2] as int,
        historicoId: row[3] as int?,
        usuarioId: row[4] as int,
        usuarioNome: row[5] as String,
        nomeArquivo: row[6] as String,
        tamanhoBytes: row[7] as int,
        mimeType: row[8] as String,
        caminho: row[9] as String,
        criadoEm: row[10] as DateTime,
      );
}

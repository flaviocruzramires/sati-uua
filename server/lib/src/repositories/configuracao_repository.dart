import 'package:postgres/postgres.dart';

import '../models/configuracao.dart';

// Chaves editáveis pela tela — sensíveis (DB_*, JWT_SECRET) nunca entram aqui.
const _chavesPermitidas = {
  'LOG_LEVEL',
  'PAGINACAO_PADRAO',
  'TITULO_SISTEMA',
  'MENSAGEM_BOAS_VINDAS',
  'SLA_HORAS_RESPOSTA',
};

class ConfiguracaoRepository {
  const ConfiguracaoRepository(this._db);
  final Connection _db;

  bool isChavePermitida(String chave) => _chavesPermitidas.contains(chave);

  Set<String> get chavesPermitidas => _chavesPermitidas;

  Future<List<Configuracao>> list() async {
    final chavesList = _chavesPermitidas.map((c) => "'$c'").join(', ');
    final rows = await _db.execute(
      Sql.named(
        'SELECT c.chave, c.valor, c.descricao, c.tipo, c.atualizado_em, '
        '       u.nome AS atualizado_por_nome '
        'FROM configuracoes c '
        'LEFT JOIN usuarios u ON u.id = c.atualizado_por '
        'WHERE c.chave IN ($chavesList) '
        'ORDER BY c.chave',
      ),
    );
    return rows.map(_fromRow).toList();
  }

  Future<Configuracao?> findByChave(String chave) async {
    if (!isChavePermitida(chave)) return null;
    final rows = await _db.execute(
      Sql.named(
        'SELECT c.chave, c.valor, c.descricao, c.tipo, c.atualizado_em, '
        '       u.nome AS atualizado_por_nome '
        'FROM configuracoes c '
        'LEFT JOIN usuarios u ON u.id = c.atualizado_por '
        'WHERE c.chave = @chave',
      ),
      parameters: {'chave': chave},
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<Configuracao?> update(
      String chave, String valor, int atualizadoPorId) async {
    if (!isChavePermitida(chave)) return null;
    final rows = await _db.execute(
      Sql.named(
        'UPDATE configuracoes '
        'SET valor = @valor, '
        '    atualizado_em = now(), '
        '    atualizado_por = @userId '
        'WHERE chave = @chave '
        'RETURNING chave, valor, descricao, tipo, atualizado_em, NULL::text AS atualizado_por_nome',
      ),
      parameters: {
        'chave': chave,
        'valor': valor,
        'userId': atualizadoPorId,
      },
    );
    if (rows.isEmpty) return null;
    // Load with join to get nome
    return findByChave(chave);
  }

  Configuracao _fromRow(ResultRow row) => Configuracao(
        chave: row[0] as String,
        valor: row[1] as String,
        descricao: row[2] as String?,
        tipo: row[3] as String,
        atualizadoEm: (row[4] as DateTime),
        atualizadoPorNome: row[5] as String?,
      );
}

import 'package:postgres/postgres.dart';

import '../models/rotina.dart';

class RotinaRepository {
  const RotinaRepository(this._db);
  final Connection _db;

  /// Retorna a árvore completa de rotinas: raízes (pais e folhas sem pai)
  /// ordenadas por `ordem`, cada pai com seus filhos ordenados. Colunas
  /// explícitas — sem `SELECT *` (ver postgres-schema-chamados).
  Future<List<Rotina>> listarTodas() async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT id, chave, nome, is_pai, rotina_pai_id, is_crud, is_chamado, '
        'rota, ordem, icone FROM rotinas '
        'ORDER BY rotina_pai_id NULLS FIRST, ordem ASC',
      ),
    );

    final todas = rows.map(_map).toList();

    // Agrupa filhos por pai preservando a ordem já vinda do banco.
    final filhosPorPai = <int, List<Rotina>>{};
    for (final r in todas) {
      if (r.rotinaPaiId != null) {
        (filhosPorPai[r.rotinaPaiId!] ??= []).add(r);
      }
    }

    // Raízes = sem pai; cada pai recebe seus filhos.
    return todas
        .where((r) => r.rotinaPaiId == null)
        .map((r) => r.withFilhos(filhosPorPai[r.id] ?? const []))
        .toList();
  }

  Rotina _map(ResultRow r) => Rotina(
        id: r[0] as int,
        chave: r[1] as String,
        nome: r[2] as String,
        isPai: r[3] as bool,
        rotinaPaiId: r[4] as int?,
        isCrud: r[5] as bool,
        isChamado: r[6] as bool,
        rota: r[7] as String?,
        ordem: r[8] as int,
        icone: r[9] as String?,
      );
}

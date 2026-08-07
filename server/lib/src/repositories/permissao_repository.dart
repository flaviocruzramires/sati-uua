import 'package:postgres/postgres.dart';

import '../models/permissao.dart';
import '../models/usuario.dart';

class PermissaoRepository {
  const PermissaoRepository(this._db);
  final Connection _db;

  /// Matriz de um papel: todas as rotinas folha + quarteto. Rotina sem linha em
  /// `rotina_permissoes` ⇒ tudo `false` (LEFT JOIN + COALESCE). Colunas
  /// explícitas — sem `SELECT *`.
  Future<List<PermissaoRotina>> matrizPorPapel(Papel papel) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT r.id, '
        'COALESCE(p.ver, false), COALESCE(p.incluir, false), '
        'COALESCE(p.alterar, false), COALESCE(p.excluir, false) '
        'FROM rotinas r '
        'LEFT JOIN rotina_permissoes p '
        '  ON p.rotina_id = r.id AND p.papel = @papel::papel_usuario '
        'WHERE r.is_pai = false '
        'ORDER BY r.rotina_pai_id NULLS FIRST, r.ordem ASC',
      ),
      parameters: {'papel': papelToString(papel)},
    );
    return rows
        .map((r) => PermissaoRotina(
              rotinaId: r[0] as int,
              ver: r[1] as bool,
              incluir: r[2] as bool,
              alterar: r[3] as bool,
              excluir: r[4] as bool,
            ))
        .toList();
  }

  /// Matriz **efetiva** de um papel, indexada pela `chave` da rotina e já
  /// normalizada pelas regras 2/4/6. Usada pelo `GET /me/permissoes` (rotina 13).
  Future<Map<String, PermissaoRotina>> matrizEfetivaPorChave(Papel papel) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT r.chave, r.id, r.is_crud, r.is_chamado, '
        'COALESCE(p.ver, false), COALESCE(p.incluir, false), '
        'COALESCE(p.alterar, false), COALESCE(p.excluir, false) '
        'FROM rotinas r '
        'LEFT JOIN rotina_permissoes p '
        '  ON p.rotina_id = r.id AND p.papel = @papel::papel_usuario '
        'WHERE r.is_pai = false',
      ),
      parameters: {'papel': papelToString(papel)},
    );

    final matriz = <String, PermissaoRotina>{};
    for (final r in rows) {
      final n = normalizarQuarteto(
        ver: r[4] as bool,
        incluir: r[5] as bool,
        alterar: r[6] as bool,
        excluir: r[7] as bool,
        isCrud: r[2] as bool,
        isChamado: r[3] as bool,
      );
      matriz[r[0] as String] = PermissaoRotina(
        rotinaId: r[1] as int,
        ver: n.ver,
        incluir: n.incluir,
        alterar: n.alterar,
        excluir: n.excluir,
      );
    }
    return matriz;
  }

  /// Matriz efetiva do **Admin**: acesso total implícito (não há linhas para
  /// Admin — ver CHECK da migration 0007). Cada rotina folha recebe o quarteto
  /// todo `true`, ainda respeitando as colunas válidas (regras 2/6) via
  /// normalização. Indexada por `chave`.
  Future<Map<String, PermissaoRotina>> matrizEfetivaAdmin() async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT chave, id, is_crud, is_chamado FROM rotinas WHERE is_pai = false',
      ),
    );
    final matriz = <String, PermissaoRotina>{};
    for (final r in rows) {
      final n = normalizarQuarteto(
        ver: true,
        incluir: true,
        alterar: true,
        excluir: true,
        isCrud: r[2] as bool,
        isChamado: r[3] as bool,
      );
      matriz[r[0] as String] = PermissaoRotina(
        rotinaId: r[1] as int,
        ver: n.ver,
        incluir: n.incluir,
        alterar: n.alterar,
        excluir: n.excluir,
      );
    }
    return matriz;
  }

  /// Grava o lote de permissões de um papel, normalizando cada quarteto no
  /// servidor (regras 2/4/6) — não confia no cliente. Upsert por
  /// `(papel, rotina_id)`. Rotinas pai/inexistentes são ignoradas.
  Future<void> salvarLote(Papel papel, List<PermissaoRotina> itens) async {
    final flagsRows = await _db.execute(
      Sql.named('SELECT id, is_crud, is_chamado FROM rotinas WHERE is_pai = false'),
    );
    final flags = <int, ({bool isCrud, bool isChamado})>{
      for (final r in flagsRows)
        r[0] as int: (isCrud: r[1] as bool, isChamado: r[2] as bool),
    };

    await _db.runTx((tx) async {
      for (final item in itens) {
        final f = flags[item.rotinaId];
        if (f == null) continue; // rotina inexistente ou pai — ignora
        final n = normalizarQuarteto(
          ver: item.ver,
          incluir: item.incluir,
          alterar: item.alterar,
          excluir: item.excluir,
          isCrud: f.isCrud,
          isChamado: f.isChamado,
        );
        await tx.execute(
          Sql.named(
            'INSERT INTO rotina_permissoes '
            '  (papel, rotina_id, ver, incluir, alterar, excluir) '
            'VALUES (@papel::papel_usuario, @rotinaId, @ver, @incluir, @alterar, @excluir) '
            'ON CONFLICT (papel, rotina_id) DO UPDATE SET '
            '  ver = EXCLUDED.ver, incluir = EXCLUDED.incluir, '
            '  alterar = EXCLUDED.alterar, excluir = EXCLUDED.excluir',
          ),
          parameters: {
            'papel': papelToString(papel),
            'rotinaId': item.rotinaId,
            'ver': n.ver,
            'incluir': n.incluir,
            'alterar': n.alterar,
            'excluir': n.excluir,
          },
        );
      }
    });
  }
}

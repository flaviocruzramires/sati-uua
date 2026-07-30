import 'package:postgres/postgres.dart';

import '../models/tipo_equipamento.dart';

class TipoEquipamentoRepository {
  const TipoEquipamentoRepository(this._db);
  final Connection _db;

  Future<({List<TipoEquipamento> data, int total})> list({
    int page = 1,
    int pageSize = 20,
    String? busca,
  }) async {
    final offset = (page - 1) * pageSize;
    final where = busca != null && busca.isNotEmpty
        ? "WHERE nome ILIKE '%' || @busca || '%'"
        : '';

    final countResult = await _db.execute(
      Sql.named('SELECT COUNT(*) FROM tipos_equipamento $where'),
      parameters: busca != null ? {'busca': busca} : {},
    );
    final total = countResult.first[0] as int;

    final rows = await _db.execute(
      Sql.named(
        'SELECT id, nome FROM tipos_equipamento $where '
        'ORDER BY nome ASC LIMIT @limit OFFSET @offset',
      ),
      parameters: {
        'limit': pageSize,
        'offset': offset,
        if (busca != null) 'busca': busca,
      },
    );

    return (
      data: rows
          .map((r) => TipoEquipamento(id: r[0] as int, nome: r[1] as String))
          .toList(),
      total: total,
    );
  }

  Future<List<TipoEquipamento>> combo() async {
    final rows = await _db.execute(
      Sql.named(
          'SELECT id, nome FROM tipos_equipamento ORDER BY nome ASC'),
    );
    return rows
        .map((r) => TipoEquipamento(id: r[0] as int, nome: r[1] as String))
        .toList();
  }

  Future<bool> existsByNome(String nome, {int? excludeId}) async {
    final sql = excludeId != null
        ? 'SELECT 1 FROM tipos_equipamento WHERE nome ILIKE @nome AND id <> @excludeId LIMIT 1'
        : 'SELECT 1 FROM tipos_equipamento WHERE nome ILIKE @nome LIMIT 1';
    final rows = await _db.execute(
      Sql.named(sql),
      parameters: {'nome': nome, if (excludeId != null) 'excludeId': excludeId},
    );
    return rows.isNotEmpty;
  }

  Future<TipoEquipamento> create(String nome) async {
    final rows = await _db.execute(
      Sql.named(
          'INSERT INTO tipos_equipamento (nome) VALUES (@nome) RETURNING id, nome'),
      parameters: {'nome': nome},
    );
    return TipoEquipamento(
        id: rows.first[0] as int, nome: rows.first[1] as String);
  }

  Future<TipoEquipamento?> update(int id, String nome) async {
    final rows = await _db.execute(
      Sql.named(
          'UPDATE tipos_equipamento SET nome = @nome WHERE id = @id RETURNING id, nome'),
      parameters: {'id': id, 'nome': nome},
    );
    if (rows.isEmpty) return null;
    return TipoEquipamento(
        id: rows.first[0] as int, nome: rows.first[1] as String);
  }

  Future<bool> delete(int id) async {
    final rows = await _db.execute(
      Sql.named(
          'DELETE FROM tipos_equipamento WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    return rows.isNotEmpty;
  }
}

import 'package:postgres/postgres.dart';

import '../models/servico.dart';

class ServicoRepository {
  const ServicoRepository(this._db);
  final Connection _db;

  Future<({List<Servico> data, int total})> list({
    int page = 1,
    int pageSize = 20,
    String? busca,
  }) async {
    final offset = (page - 1) * pageSize;
    final where = busca != null && busca.isNotEmpty
        ? "WHERE descricao ILIKE '%' || @busca || '%'"
        : '';

    final countResult = await _db.execute(
      Sql.named('SELECT COUNT(*) FROM servicos $where'),
      parameters: busca != null ? {'busca': busca} : {},
    );
    final total = countResult.first[0] as int;

    final rows = await _db.execute(
      Sql.named(
        'SELECT id, descricao FROM servicos $where '
        'ORDER BY descricao ASC LIMIT @limit OFFSET @offset',
      ),
      parameters: {
        'limit': pageSize,
        'offset': offset,
        if (busca != null) 'busca': busca,
      },
    );

    return (
      data: rows
          .map((r) => Servico(id: r[0] as int, descricao: r[1] as String))
          .toList(),
      total: total,
    );
  }

  Future<List<Servico>> combo() async {
    final rows = await _db.execute(
      Sql.named('SELECT id, descricao FROM servicos ORDER BY descricao ASC'),
    );
    return rows
        .map((r) => Servico(id: r[0] as int, descricao: r[1] as String))
        .toList();
  }

  Future<Servico> create(String descricao) async {
    final rows = await _db.execute(
      Sql.named(
          'INSERT INTO servicos (descricao) VALUES (@descricao) RETURNING id, descricao'),
      parameters: {'descricao': descricao},
    );
    return Servico(
        id: rows.first[0] as int, descricao: rows.first[1] as String);
  }

  Future<Servico?> update(int id, String descricao) async {
    final rows = await _db.execute(
      Sql.named(
          'UPDATE servicos SET descricao = @descricao WHERE id = @id RETURNING id, descricao'),
      parameters: {'id': id, 'descricao': descricao},
    );
    if (rows.isEmpty) return null;
    return Servico(
        id: rows.first[0] as int, descricao: rows.first[1] as String);
  }

  Future<bool> delete(int id) async {
    final rows = await _db.execute(
      Sql.named('DELETE FROM servicos WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    return rows.isNotEmpty;
  }
}

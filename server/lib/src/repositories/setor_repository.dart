import 'package:postgres/postgres.dart';

import '../models/setor.dart';

class SetorRepository {
  const SetorRepository(this._db);
  final Connection _db;

  Future<({List<Setor> data, int total})> list({
    int page = 1,
    int pageSize = 20,
    String? busca,
  }) async {
    final offset = (page - 1) * pageSize;
    final where = busca != null && busca.isNotEmpty
        ? "WHERE nome ILIKE '%' || @busca || '%'"
        : '';

    final countResult = await _db.execute(
      Sql.named('SELECT COUNT(*) FROM setores $where'),
      parameters: busca != null ? {'busca': busca} : {},
    );
    final total = countResult.first[0] as int;

    final rows = await _db.execute(
      Sql.named(
        'SELECT id, nome FROM setores $where '
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
          .map((r) => Setor(id: r[0] as int, nome: r[1] as String))
          .toList(),
      total: total,
    );
  }

  Future<List<Setor>> combo() async {
    final rows = await _db.execute(
      Sql.named('SELECT id, nome FROM setores ORDER BY nome ASC'),
    );
    return rows
        .map((r) => Setor(id: r[0] as int, nome: r[1] as String))
        .toList();
  }

  Future<Setor?> findById(int id) async {
    final rows = await _db.execute(
      Sql.named('SELECT id, nome FROM setores WHERE id = @id LIMIT 1'),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return Setor(id: rows.first[0] as int, nome: rows.first[1] as String);
  }

  Future<bool> existsByNome(String nome, {int? excludeId}) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT 1 FROM setores WHERE LOWER(nome) = LOWER(@nome)'
        '${excludeId != null ? ' AND id <> @excludeId' : ''} LIMIT 1',
      ),
      parameters: {
        'nome': nome,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );
    return rows.isNotEmpty;
  }

  Future<Setor> create(String nome) async {
    final rows = await _db.execute(
      Sql.named('INSERT INTO setores (nome) VALUES (@nome) RETURNING id, nome'),
      parameters: {'nome': nome},
    );
    return Setor(id: rows.first[0] as int, nome: rows.first[1] as String);
  }

  Future<Setor?> update(int id, String nome) async {
    final rows = await _db.execute(
      Sql.named(
          'UPDATE setores SET nome = @nome WHERE id = @id RETURNING id, nome'),
      parameters: {'id': id, 'nome': nome},
    );
    if (rows.isEmpty) return null;
    return Setor(id: rows.first[0] as int, nome: rows.first[1] as String);
  }

  Future<bool> delete(int id) async {
    final rows = await _db.execute(
      Sql.named('DELETE FROM setores WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    return rows.isNotEmpty;
  }
}

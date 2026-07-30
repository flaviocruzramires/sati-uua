import 'package:postgres/postgres.dart';

import '../models/equipamento.dart';

class EquipamentoRepository {
  const EquipamentoRepository(this._db);
  final Connection _db;

  Future<({List<Equipamento> data, int total})> list({
    int page = 1,
    int pageSize = 20,
    int? tipoEquipamentoId,
  }) async {
    final offset = (page - 1) * pageSize;
    final where = tipoEquipamentoId != null
        ? 'WHERE e.tipo_equipamento_id = @tipoId'
        : '';

    final countResult = await _db.execute(
      Sql.named('SELECT COUNT(*) FROM equipamentos e $where'),
      parameters:
          tipoEquipamentoId != null ? {'tipoId': tipoEquipamentoId} : {},
    );
    final total = countResult.first[0] as int;

    final rows = await _db.execute(
      Sql.named(
        'SELECT e.id, e.descricao, e.tipo_equipamento_id, te.nome, '
        '       e.setor_id, s.nome, e.ativo '
        'FROM equipamentos e '
        'JOIN tipos_equipamento te ON te.id = e.tipo_equipamento_id '
        'LEFT JOIN setores s ON s.id = e.setor_id '
        '$where '
        'ORDER BY e.descricao ASC LIMIT @limit OFFSET @offset',
      ),
      parameters: {
        'limit': pageSize,
        'offset': offset,
        if (tipoEquipamentoId != null) 'tipoId': tipoEquipamentoId,
      },
    );

    return (
      data: rows.map(_fromRow).toList(),
      total: total,
    );
  }

  Future<Equipamento?> findById(int id) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT e.id, e.descricao, e.tipo_equipamento_id, te.nome, '
        '       e.setor_id, s.nome, e.ativo '
        'FROM equipamentos e '
        'JOIN tipos_equipamento te ON te.id = e.tipo_equipamento_id '
        'LEFT JOIN setores s ON s.id = e.setor_id '
        'WHERE e.id = @id',
      ),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<Equipamento> create({
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
  }) async {
    final rows = await _db.execute(
      Sql.named(
        'INSERT INTO equipamentos (descricao, tipo_equipamento_id, setor_id) '
        'VALUES (@descricao, @tipoId, @setorId) RETURNING id',
      ),
      parameters: {
        'descricao': descricao,
        'tipoId': tipoEquipamentoId,
        'setorId': setorId,
      },
    );
    return (await findById(rows.first[0] as int))!;
  }

  Future<Equipamento?> update({
    required int id,
    required String descricao,
    required int tipoEquipamentoId,
    int? setorId,
    required bool ativo,
  }) async {
    await _db.execute(
      Sql.named(
        'UPDATE equipamentos SET descricao=@descricao, '
        'tipo_equipamento_id=@tipoId, setor_id=@setorId, ativo=@ativo '
        'WHERE id=@id',
      ),
      parameters: {
        'id': id,
        'descricao': descricao,
        'tipoId': tipoEquipamentoId,
        'setorId': setorId,
        'ativo': ativo,
      },
    );
    return findById(id);
  }

  Future<bool> delete(int id) async {
    final rows = await _db.execute(
      Sql.named('DELETE FROM equipamentos WHERE id = @id RETURNING id'),
      parameters: {'id': id},
    );
    return rows.isNotEmpty;
  }

  static Equipamento _fromRow(ResultRow r) => Equipamento(
        id: r[0] as int,
        descricao: r[1] as String,
        tipoEquipamentoId: r[2] as int,
        tipoEquipamentoNome: r[3] as String,
        setorId: r[4] as int?,
        setorNome: r[5] as String?,
        ativo: r[6] as bool,
      );
}

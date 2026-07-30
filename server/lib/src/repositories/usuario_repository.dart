import 'package:postgres/postgres.dart';

import '../models/usuario.dart';

abstract class UsuarioRepositoryBase {
  Future<Usuario?> findByLogin(String login);
  Future<Usuario?> findById(int id);
}

class UsuarioRepository implements UsuarioRepositoryBase {
  const UsuarioRepository(this._db);

  final Connection _db;

  Future<Usuario?> findByLogin(String login) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, nome, email, login, senha_hash, setor_id, papel, ativo '
        'FROM usuarios WHERE login = @login AND ativo = true LIMIT 1',
      ),
      parameters: {'login': login},
    );

    if (result.isEmpty) return null;
    final row = result.first;
    return Usuario(
      id: row[0] as int,
      nome: row[1] as String,
      email: row[2] as String,
      login: row[3] as String,
      senhaHash: row[4] as String,
      setorId: row[5] as int,
      papel: papelFromString(row[6] as String),
      ativo: row[7] as bool,
    );
  }

  Future<Usuario?> findById(int id) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, nome, email, login, senha_hash, setor_id, papel, ativo '
        'FROM usuarios WHERE id = @id LIMIT 1',
      ),
      parameters: {'id': id},
    );

    if (result.isEmpty) return null;
    final row = result.first;
    return Usuario(
      id: row[0] as int,
      nome: row[1] as String,
      email: row[2] as String,
      login: row[3] as String,
      senhaHash: row[4] as String,
      setorId: row[5] as int,
      papel: papelFromString(row[6] as String),
      ativo: row[7] as bool,
    );
  }
}

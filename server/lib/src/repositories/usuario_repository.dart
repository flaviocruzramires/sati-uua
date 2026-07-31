import 'dart:convert';

import 'package:postgres/postgres.dart';

import '../models/usuario.dart';

// O pacote postgres v3 retorna enums customizados do PostgreSQL como
// UndecodedBytes. Esta função decodifica para String corretamente.
String _pgEnum(Object? value) {
  if (value is String) return value;
  if (value is UndecodedBytes) return utf8.decode(value.bytes);
  return value.toString();
}

// DTO sem senha_hash para respostas de API
class UsuarioDto {
  const UsuarioDto({
    required this.id,
    required this.nome,
    required this.email,
    required this.login,
    required this.setorId,
    this.setorNome,
    required this.papel,
    required this.ativo,
  });

  final int id;
  final String nome;
  final String email;
  final String login;
  final int setorId;
  final String? setorNome;
  final Papel papel;
  final bool ativo;

  // senha_hash nunca incluída
  Map<String, dynamic> toJson() => {
        'id': id,
        'nome': nome,
        'email': email,
        'login': login,
        'setorId': setorId,
        'setorNome': setorNome,
        'papel': papelToString(papel),
        'ativo': ativo,
      };
}

abstract class UsuarioRepositoryBase {
  Future<Usuario?> findByLogin(String login);
  Future<Usuario?> findById(int id);
}

class UsuarioRepository implements UsuarioRepositoryBase {
  const UsuarioRepository(this._db);
  final Connection _db;

  @override
  Future<Usuario?> findByLogin(String login) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, nome, email, login, senha_hash, setor_id, papel, ativo '
        'FROM usuarios WHERE login = @login AND ativo = true LIMIT 1',
      ),
      parameters: {'login': login},
    );
    if (result.isEmpty) return null;
    return _toUsuario(result.first);
  }

  @override
  Future<Usuario?> findById(int id) async {
    final result = await _db.execute(
      Sql.named(
        'SELECT id, nome, email, login, senha_hash, setor_id, papel, ativo '
        'FROM usuarios WHERE id = @id LIMIT 1',
      ),
      parameters: {'id': id},
    );
    if (result.isEmpty) return null;
    return _toUsuario(result.first);
  }

  Future<({List<UsuarioDto> data, int total})> list({
    int page = 1,
    int pageSize = 20,
    Papel? papel,
  }) async {
    final offset = (page - 1) * pageSize;
    final where = papel != null ? "WHERE u.papel = @papel::papel_usuario" : '';

    final countResult = await _db.execute(
      Sql.named('SELECT COUNT(*) FROM usuarios u $where'),
      parameters: papel != null ? {'papel': papelToString(papel)} : {},
    );
    final total = countResult.first[0] as int;

    final rows = await _db.execute(
      Sql.named(
        'SELECT u.id, u.nome, u.email, u.login, u.setor_id, s.nome, u.papel, u.ativo '
        'FROM usuarios u '
        'JOIN setores s ON s.id = u.setor_id '
        '$where '
        'ORDER BY u.nome ASC LIMIT @limit OFFSET @offset',
      ),
      parameters: {
        'limit': pageSize,
        'offset': offset,
        if (papel != null) 'papel': papelToString(papel),
      },
    );

    return (
      data: rows.map(_toDto).toList(),
      total: total,
    );
  }

  Future<bool> existsByEmail(String email, {int? excludeId}) async {
    final sql = excludeId != null
        ? 'SELECT 1 FROM usuarios WHERE email = @email AND id <> @excludeId LIMIT 1'
        : 'SELECT 1 FROM usuarios WHERE email = @email LIMIT 1';
    final rows = await _db.execute(
      Sql.named(sql),
      parameters: {
        'email': email,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );
    return rows.isNotEmpty;
  }

  Future<bool> existsByLogin(String login, {int? excludeId}) async {
    final sql = excludeId != null
        ? 'SELECT 1 FROM usuarios WHERE login = @login AND id <> @excludeId LIMIT 1'
        : 'SELECT 1 FROM usuarios WHERE login = @login LIMIT 1';
    final rows = await _db.execute(
      Sql.named(sql),
      parameters: {
        'login': login,
        if (excludeId != null) 'excludeId': excludeId,
      },
    );
    return rows.isNotEmpty;
  }

  Future<UsuarioDto> create({
    required String nome,
    required String email,
    required String login,
    required String senhaHash,
    required int setorId,
    required Papel papel,
  }) async {
    final rows = await _db.execute(
      Sql.named(
        'INSERT INTO usuarios (nome, email, login, senha_hash, setor_id, papel) '
        'VALUES (@nome, @email, @login, @senhaHash, @setorId, @papel::papel_usuario) '
        'RETURNING id',
      ),
      parameters: {
        'nome': nome,
        'email': email,
        'login': login,
        'senhaHash': senhaHash,
        'setorId': setorId,
        'papel': papelToString(papel),
      },
    );
    return (await _findDtoById(rows.first[0] as int))!;
  }

  Future<UsuarioDto?> update({
    required int id,
    required String nome,
    required String email,
    required int setorId,
    required Papel papel,
    required bool ativo,
    String? senhaHash,
  }) async {
    if (senhaHash != null) {
      await _db.execute(
        Sql.named(
          'UPDATE usuarios SET nome=@nome, email=@email, setor_id=@setorId, '
          'papel=@papel::papel_usuario, ativo=@ativo, senha_hash=@senhaHash, '
          'atualizado_em=now() WHERE id=@id',
        ),
        parameters: {
          'id': id,
          'nome': nome,
          'email': email,
          'setorId': setorId,
          'papel': papelToString(papel),
          'ativo': ativo,
          'senhaHash': senhaHash,
        },
      );
    } else {
      await _db.execute(
        Sql.named(
          'UPDATE usuarios SET nome=@nome, email=@email, setor_id=@setorId, '
          'papel=@papel::papel_usuario, ativo=@ativo, atualizado_em=now() WHERE id=@id',
        ),
        parameters: {
          'id': id,
          'nome': nome,
          'email': email,
          'setorId': setorId,
          'papel': papelToString(papel),
          'ativo': ativo,
        },
      );
    }
    return _findDtoById(id);
  }

  Future<UsuarioDto?> _findDtoById(int id) async {
    final rows = await _db.execute(
      Sql.named(
        'SELECT u.id, u.nome, u.email, u.login, u.setor_id, s.nome, u.papel, u.ativo '
        'FROM usuarios u JOIN setores s ON s.id = u.setor_id WHERE u.id = @id LIMIT 1',
      ),
      parameters: {'id': id},
    );
    if (rows.isEmpty) return null;
    return _toDto(rows.first);
  }

  static Usuario _toUsuario(ResultRow row) => Usuario(
        id: row[0] as int,
        nome: row[1] as String,
        email: row[2] as String,
        login: row[3] as String,
        senhaHash: row[4] as String,
        setorId: row[5] as int,
        papel: papelFromString(_pgEnum(row[6])),
        ativo: row[7] as bool,
      );

  static UsuarioDto _toDto(ResultRow row) => UsuarioDto(
        id: row[0] as int,
        nome: row[1] as String,
        email: row[2] as String,
        login: row[3] as String,
        setorId: row[4] as int,
        setorNome: row[5] as String?,
        papel: papelFromString(_pgEnum(row[6])),
        ativo: row[7] as bool,
      );
}

// Bootstrap do administrador de PRODUÇÃO.
//
// Cria (ou atualiza a senha de) um usuário ADMIN a partir de variáveis de
// ambiente, sem usar o seed de desenvolvimento (`admin.ti` / `admin123`), que
// nunca deve ir para produção. Também garante um setor inicial.
//
// Variáveis lidas (com os padrões entre parênteses):
//   ADMIN_LOGIN    (admin)
//   ADMIN_SENHA    -> OBRIGATÓRIA
//   ADMIN_NOME     (Administrador)
//   ADMIN_EMAIL    (admin@local)
//   ADMIN_SETOR    (TI)
//
// Uso local apontando para o Neon (via .env ou DATABASE_URL):
//   dart run tool/create_admin.dart
import 'dart:io';

import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';

import 'package:sati_uua_server/src/config/env.dart';

Future<void> main() async {
  final packageDir = File(Platform.script.toFilePath()).parent.parent.path;
  final env = Env.load(path: '$packageDir/.env');

  final login = Platform.environment['ADMIN_LOGIN'] ?? 'admin';
  final senha = Platform.environment['ADMIN_SENHA'];
  final nome = Platform.environment['ADMIN_NOME'] ?? 'Administrador';
  final email = Platform.environment['ADMIN_EMAIL'] ?? 'admin@local';
  final setor = Platform.environment['ADMIN_SETOR'] ?? 'TI';

  if (senha == null || senha.trim().length < 6) {
    stderr.writeln(
        'ADMIN_SENHA ausente ou muito curta (mínimo 6 caracteres). Abortando.');
    exit(1);
  }

  final hash = BCrypt.hashpw(senha, BCrypt.gensalt());

  final db = await Connection.open(
    Endpoint(
      host: env.dbHost,
      port: env.dbPort,
      database: env.dbName,
      username: env.dbUser,
      password: env.dbPassword,
    ),
    settings: ConnectionSettings(
      sslMode: env.dbUseSsl ? SslMode.require : SslMode.disable,
    ),
  );

  await db.execute(
    Sql.named('INSERT INTO setores (nome) VALUES (@nome) '
        'ON CONFLICT (nome) DO NOTHING'),
    parameters: {'nome': setor},
  );

  final result = await db.execute(
    Sql.named('''
      INSERT INTO usuarios (nome, email, login, senha_hash, setor_id, papel, ativo)
      SELECT @nome, @email, @login, @hash, s.id, 'ADMIN', true
      FROM setores s WHERE s.nome = @setor
      ON CONFLICT (login) DO UPDATE
        SET senha_hash = EXCLUDED.senha_hash, ativo = true
    '''),
    parameters: {
      'nome': nome,
      'email': email,
      'login': login,
      'hash': hash,
      'setor': setor,
    },
  );

  await db.close();

  if (result.affectedRows > 0) {
    stdout.writeln('Admin de produção pronto — login: $login');
  } else {
    stderr.writeln('Nenhuma linha afetada. Verifique se o setor "$setor" existe '
        'e se as migrations já rodaram.');
    exit(1);
  }
}

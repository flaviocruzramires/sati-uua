// Ferramenta de desenvolvimento — redefine a senha do admin.ti
// Uso: dart run tool/reset_admin.dart
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import 'package:sati_uua_server/src/config/env.dart';

Future<void> main() async {
  final packageDir = File(Platform.script.toFilePath()).parent.parent.path;
  final env = Env.load(path: '$packageDir/.env');

  const novaSenha = 'admin123';
  final hash = BCrypt.hashpw(novaSenha, BCrypt.gensalt());

  final db = await Connection.open(
    Endpoint(
      host: env.dbHost,
      port: env.dbPort,
      database: env.dbName,
      username: env.dbUser,
      password: env.dbPassword,
    ),
    settings: const ConnectionSettings(sslMode: SslMode.disable),
  );

  final result = await db.execute(
    Sql.named(
      'UPDATE usuarios SET senha_hash = @hash WHERE login = @login',
    ),
    parameters: {'hash': hash, 'login': 'admin.ti'},
  );

  await db.close();

  if (result.affectedRows > 0) {
    stdout.writeln('Senha do admin.ti redefinida para: $novaSenha');
  } else {
    stdout.writeln('Usuário admin.ti não encontrado. Rode: dart run tool/migrate.dart --seed');
  }
}

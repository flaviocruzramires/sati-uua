// Testa o fluxo de login diretamente sem o servidor HTTP
import 'dart:io';
import 'package:bcrypt/bcrypt.dart';
import 'package:postgres/postgres.dart';
import 'package:sati_uua_server/src/config/env.dart';
import 'package:sati_uua_server/src/repositories/usuario_repository.dart';
import 'package:sati_uua_server/src/services/auth_service.dart';

Future<void> main() async {
  final packageDir = File(Platform.script.toFilePath()).parent.parent.path;
  final env = Env.load(path: '$packageDir/.env');

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

  final repo = UsuarioRepository(db);
  final usuario = await repo.findByLogin('admin.ti');

  if (usuario == null) {
    stdout.writeln('ERRO: usuário admin.ti não encontrado');
    await db.close();
    return;
  }

  stdout.writeln('Usuário encontrado: ${usuario.nome}, papel=${usuario.papel}');

  final valid = BCrypt.checkpw('admin123', usuario.senhaHash);
  stdout.writeln('Senha válida: $valid');

  final authService = AuthService(repo, env);
  try {
    final token = await authService.login('admin.ti', 'admin123');
    stdout.writeln('Token gerado com sucesso (${token.length} chars)');
  } catch (e) {
    stdout.writeln('ERRO no login: $e');
  }

  await db.close();
}

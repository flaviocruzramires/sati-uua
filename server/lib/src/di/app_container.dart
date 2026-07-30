import 'package:postgres/postgres.dart';

import '../config/env.dart';

/// Composition root do servidor — único lugar que instancia a conexão com o
/// banco e (nas próximas rotinas) os repositórios/serviços. Nenhum handler
/// deve instanciar `Repository`/`Service` diretamente; tudo passa por aqui
/// (ver claude-config/skills/dart-shelf-server/SKILL.md, seção "Injeção de
/// dependência").
class AppContainer {
  AppContainer._(this.db);

  final Connection db;

  // Repositórios e serviços das rotinas 01-09 serão adicionados aqui como
  // campos `late final`, todos recebendo `db` no construtor. Ex. (rotina 01):
  //   late final UsuarioRepository usuarioRepository;
  //   late final AuthService authService;

  static Future<AppContainer> create(Env env) async {
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

    return AppContainer._(db);
  }

  Future<void> close() => db.close();
}

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_router/shelf_router.dart';

import 'package:sati_uua_server/src/config/env.dart';
import 'package:sati_uua_server/src/di/app_container.dart';
import 'package:sati_uua_server/src/middlewares/cors_middleware.dart';
import 'package:sati_uua_server/src/middlewares/error_handling_middleware.dart';
import 'package:sati_uua_server/src/middlewares/logging_middleware.dart';
import 'package:sati_uua_server/src/middlewares/request_id_middleware.dart';
import 'package:sati_uua_server/src/routes/auth_route.dart';
import 'package:sati_uua_server/src/routes/chamados_route.dart';
import 'package:sati_uua_server/src/routes/dashboard_route.dart';
import 'package:sati_uua_server/src/routes/relatorios_route.dart';
import 'package:sati_uua_server/src/routes/equipamentos_route.dart';
import 'package:sati_uua_server/src/routes/health_route.dart';
import 'package:sati_uua_server/src/routes/servicos_route.dart';
import 'package:sati_uua_server/src/routes/setores_route.dart';
import 'package:sati_uua_server/src/routes/tipos_equipamento_route.dart';
import 'package:sati_uua_server/src/routes/usuarios_route.dart';

final _log = Logger('server');

void main(List<String> arguments) async {
  final env = Env.load();
  _configureLogging(env.logLevel);

  _log.info('Iniciando SATI-UUA server (env=${env.appEnv})...');

  final container = await AppContainer.create(env);
  _log.info('Conectado ao Postgres em ${env.dbHost}:${env.dbPort}/${env.dbName}');

  final router = Router()
    ..mount('/', healthRouter(container).call)
    ..mount('/', authRouter(container).call)
    ..mount('/', setoresRouter(container).call)
    ..mount('/', servicosRouter(container).call)
    ..mount('/', tiposEquipamentoRouter(container).call)
    ..mount('/', equipamentosRouter(container).call)
    ..mount('/', usuariosRouter(container).call)
    ..mount('/', chamadosRouter(container).call)
    ..mount('/', dashboardRouter(container).call)
    ..mount('/', relatoriosRouter(container).call);

  final handler = const Pipeline()
      .addMiddleware(requestIdMiddleware())
      .addMiddleware(loggingMiddleware())
      .addMiddleware(errorHandlingMiddleware())
      .addMiddleware(corsMiddleware())
      .addHandler(router.call);

  final server = await shelf_io.serve(handler, env.httpHost, env.httpPort);
  _log.info('Servidor rodando em http://${server.address.host}:${server.port}');

  ProcessSignal.sigint.watch().listen((_) async {
    _log.info('Encerrando servidor...');
    await container.close();
    await server.close(force: true);
    exit(0);
  });
}

void _configureLogging(String levelName) {
  Logger.root.level = Level.LEVELS.firstWhere(
    (level) => level.name == levelName.toUpperCase(),
    orElse: () => Level.INFO,
  );
  Logger.root.onRecord.listen((record) {
    final buffer = StringBuffer(
      '${record.time.toIso8601String()} [${record.level.name}] '
      '${record.loggerName}: ${record.message}',
    );
    if (record.error != null) buffer.write(' error=${record.error}');
    // ignore: avoid_print
    print(buffer.toString());
    if (record.stackTrace != null) {
      // ignore: avoid_print
      print(record.stackTrace);
    }
  });
}

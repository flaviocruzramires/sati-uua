import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';

/// `GET /health` — usado pelo checklist de verificação da rotina 00
/// (claude-config/rotinas/00-fundacao-infra.md) e por qualquer orquestrador
/// (docker healthcheck, uptime monitor) para saber se o processo está de pé
/// e conectado ao banco.
Router healthRouter(AppContainer container) {
  final router = Router();

  router.get('/health', (Request request) async {
    var dbStatus = 'ok';
    try {
      await container.db.execute('SELECT 1');
    } catch (_) {
      dbStatus = 'indisponivel';
    }

    return Response.ok(
      jsonEncode({'status': 'ok', 'db': dbStatus}),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}

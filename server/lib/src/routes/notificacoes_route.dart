import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';

Router notificacoesRouter(AppContainer container) {
  final router = Router();
  final repo = container.notificacaoRepository;

  router.get('/notificacoes', (Request req) async {
    final payload = requireAuth(req);
    final items = await repo.listByUsuario(payload.userId);
    return _ok(items.map((n) => n.toJson()).toList());
  });

  router.get('/notificacoes/count', (Request req) async {
    final payload = requireAuth(req);
    final count = await repo.countNaoLidas(payload.userId);
    return _ok({'naoLidas': count});
  });

  router.patch('/notificacoes/<id>/lida', (Request req, String id) async {
    final payload = requireAuth(req);
    final nId = int.tryParse(id);
    if (nId == null) return _badRequest('ID inválido');
    await repo.marcarLida(nId, payload.userId);
    return _ok({'ok': true});
  });

  router.patch('/notificacoes/todas-lidas', (Request req) async {
    final payload = requireAuth(req);
    await repo.marcarTodasLidas(payload.userId);
    return _ok({'ok': true});
  });

  return router;
}

Response _ok(Object body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response _badRequest(String msg) => Response(
      400,
      body: jsonEncode({'error': msg}),
      headers: {'content-type': 'application/json'},
    );

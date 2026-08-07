import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router rotinasRouter(AppContainer container) {
  final router = Router();
  final repo = container.rotinaRepository;

  // GET /rotinas — árvore de rotinas (pais com filhos). Dado de configuração,
  // restrito a ADMIN: consumido pela tela de permissionamento (rotina 12) e,
  // indiretamente, pelo runtime (rotina 13).
  router.get('/rotinas', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final rotinas = await repo.listarTodas();
    return _ok(rotinas.map((r) => r.toJson()).toList());
  });

  return router;
}

Response _ok(Object body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

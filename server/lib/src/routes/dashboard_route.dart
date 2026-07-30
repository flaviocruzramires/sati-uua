import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router dashboardRouter(AppContainer container) {
  final router = Router();
  final repo = container.dashboardRepository;

  router.get('/dashboard/resumo', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final dias = int.tryParse(req.url.queryParameters['dias'] ?? '30') ?? 30;
    final diasValido = [7, 30, 90].contains(dias) ? dias : 30;

    final resumo = await repo.resumo(diasValido);
    return Response.ok(
      jsonEncode(resumo.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}

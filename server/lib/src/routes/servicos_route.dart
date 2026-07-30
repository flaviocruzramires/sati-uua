import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router servicosRouter(AppContainer container) {
  final router = Router();
  final repo = container.servicoRepository;

  router.get('/servicos', (Request req) async {
    requireAuth(req);
    final page = int.tryParse(req.url.queryParameters['page'] ?? '1') ?? 1;
    final pageSize =
        int.tryParse(req.url.queryParameters['pageSize'] ?? '20') ?? 20;
    final busca = req.url.queryParameters['busca'];

    final result =
        await repo.list(page: page, pageSize: pageSize, busca: busca);
    return _ok({
      'data': result.data.map((s) => s.toJson()).toList(),
      'total': result.total,
      'page': page,
      'pageSize': pageSize,
    });
  });

  router.get('/servicos/combo', (Request req) async {
    requireAuth(req);
    final items = await repo.combo();
    return _ok(items.map((s) => s.toJson()).toList());
  });

  router.post('/servicos', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final descricao = (body['descricao'] as String?)?.trim() ?? '';
    if (descricao.isEmpty) return _badRequest('descricao é obrigatório');

    final servico = await repo.create(descricao);
    return Response(201,
        body: jsonEncode(servico.toJson()),
        headers: {'content-type': 'application/json'});
  });

  router.put('/servicos/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final descricao = (body['descricao'] as String?)?.trim() ?? '';
    if (descricao.isEmpty) return _badRequest('descricao é obrigatório');

    final servico = await repo.update(sid, descricao);
    if (servico == null) return _notFound('Serviço não encontrado');
    return _ok(servico.toJson());
  });

  router.delete('/servicos/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    final deleted = await repo.delete(sid);
    if (!deleted) return _notFound('Serviço não encontrado');
    return Response(204);
  });

  return router;
}

Response _ok(Object body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response _badRequest(String msg) => Response(400,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});

Response _notFound(String msg) => Response(404,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});

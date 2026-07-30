import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router equipamentosRouter(AppContainer container) {
  final router = Router();
  final repo = container.equipamentoRepository;

  router.get('/equipamentos', (Request req) async {
    requireAuth(req);
    final page = int.tryParse(req.url.queryParameters['page'] ?? '1') ?? 1;
    final pageSize =
        int.tryParse(req.url.queryParameters['pageSize'] ?? '20') ?? 20;
    final tipoId =
        int.tryParse(req.url.queryParameters['tipoEquipamentoId'] ?? '');

    final result = await repo.list(
        page: page, pageSize: pageSize, tipoEquipamentoId: tipoId);
    return _ok({
      'data': result.data.map((e) => e.toJson()).toList(),
      'total': result.total,
      'page': page,
      'pageSize': pageSize,
    });
  });

  router.post('/equipamentos', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final descricao = (body['descricao'] as String?)?.trim() ?? '';
    if (descricao.isEmpty) return _badRequest('descricao é obrigatório');

    final tipoId = body['tipoEquipamentoId'] as int?;
    if (tipoId == null) return _badRequest('tipoEquipamentoId é obrigatório');

    final setorId = body['setorId'] as int?;

    final eq = await repo.create(
      descricao: descricao,
      tipoEquipamentoId: tipoId,
      setorId: setorId,
    );
    return Response(201,
        body: jsonEncode(eq.toJson()),
        headers: {'content-type': 'application/json'});
  });

  router.put('/equipamentos/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final descricao = (body['descricao'] as String?)?.trim() ?? '';
    if (descricao.isEmpty) return _badRequest('descricao é obrigatório');

    final tipoId = body['tipoEquipamentoId'] as int?;
    if (tipoId == null) return _badRequest('tipoEquipamentoId é obrigatório');

    final setorId = body['setorId'] as int?;
    final ativo = body['ativo'] as bool? ?? true;

    final eq = await repo.update(
      id: sid,
      descricao: descricao,
      tipoEquipamentoId: tipoId,
      setorId: setorId,
      ativo: ativo,
    );
    if (eq == null) return _notFound('Equipamento não encontrado');
    return _ok(eq.toJson());
  });

  router.delete('/equipamentos/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    final deleted = await repo.delete(sid);
    if (!deleted) return _notFound('Equipamento não encontrado');
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

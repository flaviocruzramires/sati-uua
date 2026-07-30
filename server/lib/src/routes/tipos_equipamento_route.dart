import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router tiposEquipamentoRouter(AppContainer container) {
  final router = Router();
  final repo = container.tipoEquipamentoRepository;

  router.get('/tipos-equipamento', (Request req) async {
    requireAuth(req);
    final page = int.tryParse(req.url.queryParameters['page'] ?? '1') ?? 1;
    final pageSize =
        int.tryParse(req.url.queryParameters['pageSize'] ?? '20') ?? 20;
    final busca = req.url.queryParameters['busca'];

    final result =
        await repo.list(page: page, pageSize: pageSize, busca: busca);
    return _ok({
      'data': result.data.map((t) => t.toJson()).toList(),
      'total': result.total,
      'page': page,
      'pageSize': pageSize,
    });
  });

  router.get('/tipos-equipamento/combo', (Request req) async {
    requireAuth(req);
    final items = await repo.combo();
    return _ok(items.map((t) => t.toJson()).toList());
  });

  router.post('/tipos-equipamento', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final nome = (body['nome'] as String?)?.trim() ?? '';
    if (nome.isEmpty) return _badRequest('nome é obrigatório');

    if (await repo.existsByNome(nome)) {
      return _conflict('Já existe um tipo com este nome');
    }

    final tipo = await repo.create(nome);
    return Response(201,
        body: jsonEncode(tipo.toJson()),
        headers: {'content-type': 'application/json'});
  });

  router.put('/tipos-equipamento/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final nome = (body['nome'] as String?)?.trim() ?? '';
    if (nome.isEmpty) return _badRequest('nome é obrigatório');

    if (await repo.existsByNome(nome, excludeId: sid)) {
      return _conflict('Já existe um tipo com este nome');
    }

    final tipo = await repo.update(sid, nome);
    if (tipo == null) return _notFound('Tipo não encontrado');
    return _ok(tipo.toJson());
  });

  router.delete('/tipos-equipamento/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    try {
      final deleted = await repo.delete(sid);
      if (!deleted) return _notFound('Tipo não encontrado');
      return Response(204);
    } on Exception catch (e) {
      if (e.toString().contains('violates foreign key')) {
        return _conflict(
            'Não é possível excluir: há equipamentos vinculados a este tipo');
      }
      rethrow;
    }
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

Response _conflict(String msg) => Response(409,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router setoresRouter(AppContainer container) {
  final router = Router();
  final repo = container.setorRepository;

  router.get('/setores', (Request req) async {
    requireAuth(req); // autenticado, qualquer papel
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

  router.get('/setores/combo', (Request req) async {
    requireAuth(req);
    final items = await repo.combo();
    return _ok(items.map((s) => s.toJson()).toList());
  });

  router.post('/setores', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final nome = (body['nome'] as String?)?.trim() ?? '';
    if (nome.isEmpty) return _badRequest('nome é obrigatório');

    if (await repo.existsByNome(nome)) {
      return _conflict('Já existe um setor com este nome');
    }

    final setor = await repo.create(nome);
    return Response(201,
        body: jsonEncode(setor.toJson()),
        headers: {'content-type': 'application/json'});
  });

  router.put('/setores/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final nome = (body['nome'] as String?)?.trim() ?? '';
    if (nome.isEmpty) return _badRequest('nome é obrigatório');

    if (await repo.existsByNome(nome, excludeId: sid)) {
      return _conflict('Já existe um setor com este nome');
    }

    final setor = await repo.update(sid, nome);
    if (setor == null) return _notFound('Setor não encontrado');
    return _ok(setor.toJson());
  });

  router.delete('/setores/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final sid = int.tryParse(id);
    if (sid == null) return _badRequest('id inválido');

    try {
      final deleted = await repo.delete(sid);
      if (!deleted) return _notFound('Setor não encontrado');
      return Response(204);
    } on Exception catch (e) {
      // FK RESTRICT: usuário vinculado ao setor
      if (e.toString().contains('violates foreign key')) {
        return _conflict(
            'Não é possível excluir: há usuários vinculados a este setor');
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

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router configuracoesRouter(AppContainer container) {
  final router = Router();
  final repo = container.configuracaoRepository;

  router.get('/configuracoes', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final configs = await repo.list();
    return _ok(configs.map((c) => c.toJson()).toList());
  });

  router.put('/configuracoes/<chave>', (Request req, String chave) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    if (!repo.isChavePermitida(chave)) {
      return _forbidden('Chave não editável pela interface');
    }

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final valor = (body['valor'] as String?)?.trim();
    if (valor == null || valor.isEmpty) {
      return _badRequest('valor é obrigatório');
    }

    // Validate value matches tipo
    final current = await repo.findByChave(chave);
    if (current == null) {
      return _notFound('Configuração não encontrada');
    }
    if (current.tipo == 'int' && int.tryParse(valor) == null) {
      return _badRequest('valor deve ser inteiro para chave do tipo int');
    }
    if (current.tipo == 'bool' && valor != 'true' && valor != 'false') {
      return _badRequest(
          'valor deve ser "true" ou "false" para chave do tipo bool');
    }

    final updated = await repo.update(chave, valor, payload.userId);
    if (updated == null) return _notFound('Configuração não encontrada');
    return _ok(updated.toJson());
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

Response _forbidden(String msg) => Response(403,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});

import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/permissao.dart';
import '../models/usuario.dart';

Router permissoesRouter(AppContainer container) {
  final router = Router();
  final repo = container.permissaoRepository;

  // GET /permissoes?papel=GERENCIA — matriz configurável de um papel (rotina 12).
  // Restrito a ADMIN. Admin não é papel configurável (400).
  router.get('/permissoes', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final papel = _parsePapelAlvo(req);
    if (papel == null) return _badRequest('papel inválido ou não configurável');

    final matriz = await repo.matrizPorPapel(papel);
    return _ok(matriz.map((p) => p.toJson()).toList());
  });

  // PUT /permissoes?papel=GERENCIA — grava o lote (rotina 12). O servidor
  // normaliza pelas regras 2/4/6 e devolve a matriz já normalizada.
  router.put('/permissoes', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.admin);

    final papel = _parsePapelAlvo(req);
    if (papel == null) return _badRequest('papel inválido ou não configurável');

    final body = jsonDecode(await req.readAsString());
    if (body is! List) return _badRequest('corpo deve ser uma lista de permissões');

    final itens = <PermissaoRotina>[];
    for (final e in body) {
      if (e is! Map) return _badRequest('item inválido na lista');
      final rotinaId = e['rotinaId'];
      if (rotinaId is! int) return _badRequest('rotinaId inteiro é obrigatório');
      itens.add(PermissaoRotina(
        rotinaId: rotinaId,
        ver: e['ver'] == true,
        incluir: e['incluir'] == true,
        alterar: e['alterar'] == true,
        excluir: e['excluir'] == true,
      ));
    }

    await repo.salvarLote(papel, itens);
    final matriz = await repo.matrizPorPapel(papel);
    return _ok(matriz.map((p) => p.toJson()).toList());
  });

  // GET /me/permissoes — matriz efetiva do usuário logado (rotina 13).
  // Resolve o papel do JWT → permissões normalizadas, indexadas por `chave`.
  // Admin recebe tudo liberado (bypass).
  router.get('/me/permissoes', (Request req) async {
    final payload = requireAuth(req);

    final matriz = payload.papel == Papel.admin
        ? await repo.matrizEfetivaAdmin()
        : await repo.matrizEfetivaPorChave(payload.papel);

    return _ok({
      for (final entry in matriz.entries)
        entry.key: {
          'ver': entry.value.ver,
          'incluir': entry.value.incluir,
          'alterar': entry.value.alterar,
          'excluir': entry.value.excluir,
        },
    });
  });

  return router;
}

/// Papel-alvo do query param, restrito aos configuráveis (nunca Admin).
Papel? _parsePapelAlvo(Request req) {
  final raw = req.url.queryParameters['papel'];
  if (raw == null) return null;
  final Papel papel;
  try {
    papel = papelFromString(raw);
  } catch (_) {
    return null;
  }
  if (papel == Papel.admin) return null; // Admin não é configurável
  return papel;
}

Response _ok(Object body) => Response.ok(
      jsonEncode(body),
      headers: {'content-type': 'application/json'},
    );

Response _badRequest(String msg) => Response(400,
    body: jsonEncode({'error': msg}),
    headers: {'content-type': 'application/json'});

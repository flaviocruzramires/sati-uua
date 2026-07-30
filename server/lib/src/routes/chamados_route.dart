import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router chamadosRouter(AppContainer container) {
  final router = Router();
  final repo = container.chamadoRepository;
  final historicoRepo = container.chamadoHistoricoRepository;

  router.get('/chamados', (Request req) async {
    final payload = requireAuth(req);
    final params = req.url.queryParameters;
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final pageSize = int.tryParse(params['pageSize'] ?? '20') ?? 20;
    final situacao = params['situacao'];

    // SOLICITANTE só vê os próprios chamados
    final solicitanteId = payload.papel == Papel.solicitante
        ? payload.userId
        : (int.tryParse(params['solicitanteId'] ?? ''));
    final responsavelId = int.tryParse(params['responsavelId'] ?? '');

    final result = await repo.list(
      page: page,
      pageSize: pageSize,
      situacao: situacao,
      solicitanteId: solicitanteId,
      responsavelId: responsavelId,
    );
    return _ok({
      'data': result.data.map((c) => c.toJson()).toList(),
      'total': result.total,
      'page': page,
      'pageSize': pageSize,
    });
  });

  router.get('/chamados/<id>', (Request req, String id) async {
    requireAuth(req);
    final chamadoId = int.tryParse(id);
    if (chamadoId == null) return _badRequest('ID inválido');
    final chamado = await repo.findById(chamadoId);
    if (chamado == null) return _notFound();
    final historico = await historicoRepo.listByChamado(chamadoId);
    return _ok({
      ...chamado.toJson(),
      'historico': historico.map((h) => h.toJson()).toList(),
    });
  });

  router.post('/chamados', (Request req) async {
    final payload = requireAuth(req);
    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;

    final descricao = (body['descricao'] as String?)?.trim() ?? '';
    if (descricao.isEmpty) return _badRequest('Descrição é obrigatória');

    final equipamentoId = body['equipamentoId'] as int?;
    final servicoId = body['servicoId'] as int?;

    final chamado = await repo.create(
      descricao: descricao,
      solicitanteId: payload.userId,
      equipamentoId: equipamentoId,
      servicoId: servicoId,
    );
    return Response(201,
        body: jsonEncode(chamado.toJson()),
        headers: {'content-type': 'application/json'});
  });

  router.put('/chamados/<id>', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final chamadoId = int.tryParse(id);
    if (chamadoId == null) return _badRequest('ID inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final responsavelId = body['responsavelId'] as int?;
    if (responsavelId == null) return _badRequest('responsavelId é obrigatório');

    final chamado = await repo.atribuirResponsavel(
      id: chamadoId,
      responsavelId: responsavelId,
    );
    if (chamado == null) return _notFound();
    return _ok(chamado.toJson());
  });

  router.post('/chamados/<id>/historico', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final chamadoId = int.tryParse(id);
    if (chamadoId == null) return _badRequest('ID inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final descricao = (body['descricao'] as String?)?.trim() ?? '';
    if (descricao.isEmpty) return _badRequest('Descrição é obrigatória');

    final marcaEncerramento = body['marcaEncerramento'] as bool? ?? false;
    final dataRetornoRaw = body['dataRetorno'] as String?;
    final dataRetorno = dataRetornoRaw != null
        ? DateTime.tryParse(dataRetornoRaw) ?? DateTime.now().toUtc()
        : DateTime.now().toUtc();

    try {
      final detalhe = await historicoRepo.registrar(
        chamadoId: chamadoId,
        responsavelId: payload.userId,
        dataRetorno: dataRetorno,
        descricao: descricao,
        marcaEncerramento: marcaEncerramento,
      );
      return Response(201,
          body: jsonEncode(detalhe.toJson()),
          headers: {'content-type': 'application/json'});
    } on StateError catch (e) {
      return _badRequest(e.message);
    }
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

Response _notFound() => Response(
      404,
      body: jsonEncode({'error': 'Não encontrado'}),
      headers: {'content-type': 'application/json'},
    );

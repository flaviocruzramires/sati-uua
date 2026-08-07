import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/permissao.dart';
import '../models/usuario.dart';

Router chamadosRouter(AppContainer container) {
  final router = Router();
  final repo = container.chamadoRepository;
  final historicoRepo = container.chamadoHistoricoRepository;
  final notifService = container.notificacaoService;
  final anexoRepo = container.anexoRepository;
  final permRepo = container.permissaoRepository;

  // GET /chamados
  router.get('/chamados', (Request req) async {
    final payload = requireAuth(req);
    final params = req.url.queryParameters;
    final page = int.tryParse(params['page'] ?? '1') ?? 1;
    final pageSize = int.tryParse(params['pageSize'] ?? '20') ?? 20;
    final situacao = params['situacao'];

    // Eixo "meus × todos" (rotina 10): Atendente, Gerência e Admin enxergam
    // todos os chamados; Solicitante sempre só os próprios. Este é o ÚNICO
    // ponto desse controle e é independente do permissionamento (rotinas 11-13).
    const veemTodos = {Papel.atendente, Papel.gerencia, Papel.admin};
    final solicitanteId = veemTodos.contains(payload.papel)
        ? (int.tryParse(params['solicitanteId'] ?? ''))
        : payload.userId;
    final responsavelId = int.tryParse(params['responsavelId'] ?? '');

    final dataAberturaInicio = _parseDate(params['dataAberturaInicio']);
    final dataAberturaFim = params['dataAberturaFim'] != null
        ? (_parseDate(params['dataAberturaFim'])?.add(const Duration(days: 1)))
        : null;

    final result = await repo.list(
      page: page,
      pageSize: pageSize,
      situacao: situacao,
      solicitanteId: solicitanteId,
      responsavelId: responsavelId,
      dataAberturaInicio: dataAberturaInicio,
      dataAberturaFim: dataAberturaFim,
    );
    return _ok({
      'data': result.data.map((c) => c.toJson()).toList(),
      'total': result.total,
      'page': page,
      'pageSize': pageSize,
    });
  });

  // GET /chamados/:id
  router.get('/chamados/<id>', (Request req, String id) async {
    requireAuth(req);
    final chamadoId = int.tryParse(id);
    if (chamadoId == null) return _badRequest('ID inválido');
    final chamado = await repo.findById(chamadoId);
    if (chamado == null) return _notFound();
    final historico = await historicoRepo.listByChamado(chamadoId);
    final anexos = await anexoRepo.listByChamado(chamadoId);
    return _ok({
      ...chamado.toJson(),
      'historico': historico.map((h) => h.toJson()).toList(),
      'anexos': anexos.map((a) => a.toJson()).toList(),
    });
  });

  // POST /chamados
  router.post('/chamados', (Request req) async {
    final payload = requireAuth(req);
    await requirePermissao(req, permRepo, 'chamados.abertura', Acao.incluir);
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

    // Notificar atendentes e admins
    await notifService.novoChamado(chamado.id, descricao);

    return Response(201,
        body: jsonEncode(chamado.toJson()),
        headers: {'content-type': 'application/json'});
  });

  // PUT /chamados/:id  (atribuir responsável)
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

    // Notificar solicitante
    await notifService.chamadoAssumido(chamadoId, payload.nome ?? 'Atendente');

    return _ok(chamado.toJson());
  });

  // PATCH /chamados/:id/terceiro
  router.patch('/chamados/<id>/terceiro', (Request req, String id) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final chamadoId = int.tryParse(id);
    if (chamadoId == null) return _badRequest('ID inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final envolveTerceiro = body['envolveTerceiro'] as bool? ?? false;
    final nomeTerceiro = (body['nomeTerceiro'] as String?)?.trim();

    if (envolveTerceiro && (nomeTerceiro == null || nomeTerceiro.isEmpty)) {
      return _badRequest('nomeTerceiro é obrigatório quando envolveTerceiro = true');
    }

    final chamado = await repo.atualizarTerceiro(
      id: chamadoId,
      envolveTerceiro: envolveTerceiro,
      nomeTerceiro: nomeTerceiro,
    );
    if (chamado == null) return _notFound();
    return _ok(chamado.toJson());
  });

  // POST /chamados/:id/historico  (atendente)
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
    final dataPrevistaRaw = body['dataPrevistaRetorno'] as String?;
    final dataPrevistaRetorno =
        dataPrevistaRaw != null ? DateTime.tryParse(dataPrevistaRaw) : null;

    try {
      final detalhe = await historicoRepo.registrar(
        chamadoId: chamadoId,
        responsavelId: payload.userId,
        dataRetorno: dataRetorno,
        descricao: descricao,
        marcaEncerramento: marcaEncerramento,
        dataPrevistaRetorno: dataPrevistaRetorno,
      );

      // Notificações
      if (marcaEncerramento) {
        await notifService.chamadoEncerrado(chamadoId);
      } else {
        await notifService.retornoAtendente(
            chamadoId, payload.nome ?? 'Atendente');
      }

      return Response(201,
          body: jsonEncode(detalhe.toJson()),
          headers: {'content-type': 'application/json'});
    } on StateError catch (e) {
      return _badRequest(e.message);
    }
  });

  // POST /chamados/:id/retorno-solicitante
  router.post('/chamados/<id>/retorno-solicitante',
      (Request req, String id) async {
    final payload = requireAuth(req);

    final chamadoId = int.tryParse(id);
    if (chamadoId == null) return _badRequest('ID inválido');

    final body = jsonDecode(await req.readAsString()) as Map<String, dynamic>;
    final descricao = (body['descricao'] as String?)?.trim() ?? '';
    if (descricao.isEmpty) return _badRequest('Descrição é obrigatória');

    try {
      final detalhe = await historicoRepo.registrarRetornoSolicitante(
        chamadoId: chamadoId,
        solicitanteId: payload.userId,
        descricao: descricao,
      );

      await notifService.retornoSolicitante(chamadoId, payload.nome ?? 'Solicitante');

      return Response(201,
          body: jsonEncode(detalhe.toJson()),
          headers: {'content-type': 'application/json'});
    } on StateError catch (e) {
      return _badRequest(e.message);
    }
  });

  return router;
}

DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
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

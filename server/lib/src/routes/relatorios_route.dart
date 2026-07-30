import 'dart:convert';

import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import '../di/app_container.dart';
import '../middlewares/auth_middleware.dart';
import '../models/usuario.dart';

Router relatoriosRouter(AppContainer container) {
  final router = Router();
  final repo = container.relatorioRepository;

  router.get('/relatorios/chamados', (Request req) async {
    final payload = requireAuth(req);
    requirePapel(payload, Papel.atendente);

    final p = req.url.queryParameters;
    final page = int.tryParse(p['page'] ?? '1') ?? 1;
    final pageSize = int.tryParse(p['pageSize'] ?? '20') ?? 20;

    final result = await repo.chamados(
      page: page,
      pageSize: pageSize,
      situacao: p['situacao'],
      solicitanteId: int.tryParse(p['solicitanteId'] ?? ''),
      atendenteId: int.tryParse(p['atendenteId'] ?? ''),
      equipamentoId: int.tryParse(p['equipamentoId'] ?? ''),
      servicoId: int.tryParse(p['servicoId'] ?? ''),
      aberturaDe: _parseDate(p['aberturaDe']),
      aberturaAte: _parseDate(p['aberturaAte']),
      fechamentoDe: _parseDate(p['fechamentoDe']),
      fechamentoAte: _parseDate(p['fechamentoAte']),
    );

    return Response.ok(
      jsonEncode(result.toJson()),
      headers: {'content-type': 'application/json'},
    );
  });

  return router;
}

DateTime? _parseDate(String? s) {
  if (s == null || s.isEmpty) return null;
  return DateTime.tryParse(s);
}

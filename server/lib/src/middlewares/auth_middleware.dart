import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../errors/app_exception.dart';
import '../models/permissao.dart';
import '../models/usuario.dart';
import '../repositories/permissao_repository.dart';
import '../services/auth_service.dart';

const _kUserKey = 'authenticatedUser';

/// Caminho público de download de anexo: /anexos/<uuid>/arquivo
final _anexoDownloadRegex = RegExp(
  r'^/anexos/[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/arquivo$',
);

/// Popula o contexto da request com o payload do Bearer token quando presente.
/// Rotas públicas (/auth/*, /health) passam sem token; rotas protegidas
/// devem chamar [requireAuth] para garantir que o payload existe.
Middleware authMiddleware(AuthService authService) {
  return (Handler inner) {
    return (Request request) async {
      // requestedUri.path é o caminho real sem manipulação de roteamento
      final path = request.requestedUri.path;
      // Download de anexo por token UUID: público, para abrir direto no
      // navegador/dispositivo (onde não há como enviar o header Authorization).
      // O token é não-adivinhável, então não há risco de enumeração.
      final isDownloadAnexo = request.method == 'GET' &&
          _anexoDownloadRegex.hasMatch(path);
      // Rotas públicas: não exigem token
      if (path == '/' ||
          path.startsWith('/auth/') ||
          path == '/health' ||
          isDownloadAnexo) {
        return inner(request);
      }

      final authHeader = request.headers['authorization'];
      if (authHeader == null || !authHeader.startsWith('Bearer ')) {
        return _unauthorized('Token ausente');
      }

      final token = authHeader.substring(7);
      try {
        final payload = authService.verifyToken(token);
        final updated = request.change(context: {
          ..._safeContext(request.context),
          _kUserKey: payload,
        });
        return inner(updated);
      } on AuthException catch (e) {
        return _unauthorized(e.message);
      }
    };
  };
}

/// Extrai o payload autenticado do contexto — lança 401 se ausente.
TokenPayload requireAuth(Request request) {
  final payload = request.context[_kUserKey];
  if (payload == null) throw const AuthException('Não autenticado');
  return payload as TokenPayload;
}

/// Lança 403 se o papel não for suficiente.
///
/// Escada **legada** de autorização. Gerência entra acima de Solicitante e
/// abaixo de Atendente, de forma que `requirePapel(Papel.atendente)` continua
/// barrando Gerência nos endpoints de atendimento (assumir/responder chamado).
/// A partir da rotina 13, a autorização das rotinas de CRUD passa a vir da
/// matriz de permissões (papel×rotina), não desta escada.
void requirePapel(TokenPayload payload, Papel papel) {
  final order = [
    Papel.solicitante,
    Papel.gerencia,
    Papel.atendente,
    Papel.admin,
  ];
  if (order.indexOf(payload.papel) < order.indexOf(papel)) {
    throw const AppException.forbidden();
  }
}

/// Autorização por **matriz de permissões** (rotina 13) — defesa em
/// profundidade nas rotas de CRUD. Lê o papel do JWT, consulta a matriz efetiva
/// e lança 403 se a ação faltar. Admin tem bypass (acesso total).
///
/// Ex.: `POST /setores` → `requirePermissao(req, repo, 'cadastros.setores', Acao.incluir)`.
Future<void> requirePermissao(
  Request request,
  PermissaoRepository repo,
  String chave,
  Acao acao,
) async {
  final payload = requireAuth(request);
  if (payload.papel == Papel.admin) return; // bypass

  final matriz = await repo.matrizEfetivaPorChave(payload.papel);
  final perm = matriz[chave];
  if (perm == null || !perm.pode(acao)) {
    throw const AppException.forbidden();
  }
}

Response _unauthorized(String msg) => Response(
      401,
      body: jsonEncode({'error': msg}),
      headers: {'content-type': 'application/json'},
    );

Map<String, Object> _safeContext(Map<String, Object> ctx) => Map.of(ctx);

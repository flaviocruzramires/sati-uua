import 'dart:convert';

import 'package:shelf/shelf.dart';

import '../models/usuario.dart';
import '../services/auth_service.dart';

const _kUserKey = 'authenticatedUser';

/// Popula o contexto da request com o payload do Bearer token quando presente.
/// Rotas públicas (/auth/*, /health) passam sem token; rotas protegidas
/// devem chamar [requireAuth] para garantir que o payload existe.
Middleware authMiddleware(AuthService authService) {
  return (Handler inner) {
    return (Request request) async {
      final path = request.url.path;
      // Rotas públicas: não exigem token
      if (path.startsWith('auth/') || path == 'health') {
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
void requirePapel(TokenPayload payload, Papel papel) {
  final order = [Papel.solicitante, Papel.atendente, Papel.admin];
  if (order.indexOf(payload.papel) < order.indexOf(papel)) {
    throw _ForbiddenException();
  }
}

class _ForbiddenException implements Exception {}

Response _unauthorized(String msg) => Response(
      401,
      body: jsonEncode({'error': msg}),
      headers: {'content-type': 'application/json'},
    );

Map<String, Object> _safeContext(Map<String, Object> ctx) => Map.of(ctx);

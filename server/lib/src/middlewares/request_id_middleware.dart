import 'package:shelf/shelf.dart';
import 'package:uuid/uuid.dart';

const requestIdHeader = 'x-request-id';
const _requestIdContextKey = 'requestId';

const _uuid = Uuid();

/// Gera (ou propaga, se já vier do cliente/proxy) um id único por requisição,
/// usado no log e devolvido no header de resposta — primeiro middleware do
/// pipeline (ver claude-config/skills/dart-shelf-server/SKILL.md).
Middleware requestIdMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final incoming = request.headers[requestIdHeader];
      final requestId =
          (incoming != null && incoming.isNotEmpty) ? incoming : _uuid.v4();

      final updatedRequest =
          request.change(context: {_requestIdContextKey: requestId});
      final response = await innerHandler(updatedRequest);
      return response.change(headers: {requestIdHeader: requestId});
    };
  };
}

extension RequestIdContext on Request {
  String get requestId =>
      (context[_requestIdContextKey] as String?) ?? 'sem-id';
}

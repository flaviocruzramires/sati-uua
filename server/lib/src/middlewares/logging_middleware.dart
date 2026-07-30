import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import 'request_id_middleware.dart';

final _accessLog = Logger('http.access');

/// Loga uma linha por requisição (rota, método, status, duração, request id).
/// Nunca loga corpo da requisição/resposta (poderia conter senha ou token) —
/// ver regra de logging em claude-config/skills/dart-shelf-server/SKILL.md.
Middleware loggingMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      final stopwatch = Stopwatch()..start();
      Response response;
      try {
        response = await innerHandler(request);
      } catch (error, stackTrace) {
        stopwatch.stop();
        _accessLog.severe(
          '${request.method} ${request.requestedUri.path} '
          'request_id=${request.requestId} duration_ms=${stopwatch.elapsedMilliseconds} '
          'status=erro_nao_tratado',
          error,
          stackTrace,
        );
        rethrow;
      }
      stopwatch.stop();
      _accessLog.info(
        '${request.method} ${request.requestedUri.path} '
        'status=${response.statusCode} duration_ms=${stopwatch.elapsedMilliseconds} '
        'request_id=${request.requestId}',
      );
      return response;
    };
  };
}

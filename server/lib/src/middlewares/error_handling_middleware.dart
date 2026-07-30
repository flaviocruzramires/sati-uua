import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:shelf/shelf.dart';

import '../errors/app_exception.dart';
import 'request_id_middleware.dart';

final _errorLog = Logger('http.error');

/// Converte qualquer [AppException] lançada por um handler/service no
/// formato JSON padronizado `{"error": {"code", "message"}}`. Exceções não
/// mapeadas viram um `500` genérico — o cliente nunca recebe stack trace
/// (ver claude-config/skills/dart-shelf-server/SKILL.md).
Middleware errorHandlingMiddleware() {
  return (Handler innerHandler) {
    return (Request request) async {
      try {
        return await innerHandler(request);
      } on AppException catch (appException) {
        return Response(
          appException.statusCode,
          body: jsonEncode(appException.toJson()),
          headers: {'content-type': 'application/json'},
        );
      } catch (error, stackTrace) {
        _errorLog.severe(
          'Erro não tratado request_id=${request.requestId}',
          error,
          stackTrace,
        );
        return Response.internalServerError(
          body: jsonEncode({
            'error': {
              'code': 'internal_error',
              'message': 'Erro interno. Tente novamente mais tarde.',
            },
          }),
          headers: {'content-type': 'application/json'},
        );
      }
    };
  };
}

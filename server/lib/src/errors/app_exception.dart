/// Exceção de domínio padronizada. Todo erro esperado (validação, conflito de
/// unicidade, não encontrado, não autorizado) deve ser lançado como
/// [AppException] em vez de deixar vazar uma exceção genérica — o middleware
/// de erro (`middlewares/error_handling_middleware.dart`) converte isso no
/// formato JSON único `{"error": {"code": ..., "message": ...}}` (ver
/// claude-config/skills/dart-shelf-server/SKILL.md).
class AppException implements Exception {
  const AppException(this.statusCode, this.code, this.message);

  /// Não autenticado — token ausente/inválido/expirado.
  const AppException.unauthorized([String message = 'Não autenticado'])
      : this(401, 'unauthorized', message);

  /// Autenticado, mas sem permissão para a ação (papel insuficiente).
  const AppException.forbidden(
      [String message = 'Sem permissão para esta ação'])
      : this(403, 'forbidden', message);

  /// Registro não encontrado.
  const AppException.notFound([String message = 'Registro não encontrado'])
      : this(404, 'not_found', message);

  /// Conflito de unicidade (e-mail/login/nome duplicado) ou de integridade
  /// referencial (exclusão com vínculo — FK RESTRICT).
  const AppException.conflict(String message) : this(409, 'conflict', message);

  /// Erro de validação de entrada.
  const AppException.badRequest(String message)
      : this(400, 'bad_request', message);

  final int statusCode;
  final String code;
  final String message;

  Map<String, dynamic> toJson() => {
        'error': {'code': code, 'message': message},
      };

  @override
  String toString() => 'AppException($statusCode, $code, $message)';
}

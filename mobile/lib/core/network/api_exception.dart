import 'package:dio/dio.dart';

class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException e) {
    return switch (e.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        const ApiException(message: 'Tempo de conexão esgotado'),
      DioExceptionType.badResponse => ApiException(
          message: _extractMessage(e.response),
          statusCode: e.response?.statusCode),
      DioExceptionType.connectionError =>
        const ApiException(message: 'Sem conexão com o servidor'),
      _ => ApiException(message: e.message ?? 'Erro desconhecido'),
    };
  }

  static String _extractMessage(Response<dynamic>? response) {
    try {
      final body = response?.data;
      if (body is Map<String, dynamic>) {
        return body['message'] as String? ?? 'Erro ${response?.statusCode}';
      }
    } catch (_) {}
    return 'Erro ${response?.statusCode}';
  }

  @override
  String toString() => 'ApiException($statusCode): $message';
}

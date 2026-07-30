import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_exception.dart';

const _kBaseUrl = 'http://localhost:8080';

class ApiClient {
  ApiClient({required String? authToken}) : _dio = _build(authToken);

  final Dio _dio;

  static Dio _build(String? authToken) {
    final dio = Dio(BaseOptions(
      baseUrl: _kBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        if (authToken != null) 'Authorization': 'Bearer $authToken',
      },
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (e, handler) {
        throw ApiException.fromDioException(e);
      },
    ));

    return dio;
  }

  Future<Response<T>> get<T>(String path,
      {Map<String, dynamic>? queryParameters}) =>
      _dio.get(path, queryParameters: queryParameters);

  Future<Response<T>> post<T>(String path, {Object? data}) =>
      _dio.post(path, data: data);

  Future<Response<T>> put<T>(String path, {Object? data}) =>
      _dio.put(path, data: data);

  Future<Response<T>> delete<T>(String path) => _dio.delete(path);
}

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(authToken: null);
});

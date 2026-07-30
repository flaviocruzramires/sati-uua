import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/network/auth_storage.dart';

class AuthService {
  const AuthService(this._client, this._storage);

  final ApiClient _client;
  final AuthStorage _storage;

  Future<void> login(String login, String senha) async {
    final response = await _client.post<Map<String, dynamic>>(
      '/auth/login',
      data: {'login': login, 'senha': senha},
    );
    final token = (response.data as Map<String, dynamic>)['token'] as String;
    await _storage.writeToken(token);
  }

  Future<void> logout() => _storage.deleteToken();

  Future<bool> isAuthenticated() async {
    final token = await _storage.readToken();
    return token != null;
  }
}

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(
    ref.watch(apiClientProvider),
    ref.watch(authStorageProvider),
  );
});

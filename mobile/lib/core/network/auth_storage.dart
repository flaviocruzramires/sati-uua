import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _kTokenKey = 'jwt_token';

class AuthStorage {
  const AuthStorage(this._storage);

  final FlutterSecureStorage _storage;

  Future<String?> readToken() => _storage.read(key: _kTokenKey);

  Future<void> writeToken(String token) =>
      _storage.write(key: _kTokenKey, value: token);

  Future<void> deleteToken() => _storage.delete(key: _kTokenKey);
}

final authStorageProvider = Provider<AuthStorage>((ref) {
  return const AuthStorage(FlutterSecureStorage());
});
